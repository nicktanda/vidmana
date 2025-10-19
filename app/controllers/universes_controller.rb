class UniversesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe, only: [:show, :edit, :update, :destroy, :regenerate]

  MODEL_OPTIONS = {
    'x-ai/grok-4-fast' => 'Grok 4 Fast',
    'x-ai/grok-3-mini' => 'Grok 3 Mini',
    'qwen/qwen-2.5-72b-instruct' => 'Qwen 2.5',
    'qwen/qwen3-coder' => 'Qwen 3 Coder'
  }.freeze

  DEFAULT_MODEL = 'x-ai/grok-4-fast'.freeze

  def index
    @universes = current_user.universes.order(created_at: :desc)

    # For ChatGPT-style interface: show API response if available
    @api_response = session.delete(:api_response)
    @user_prompt = session.delete(:user_prompt)
    @selected_model = session.delete(:selected_model) || DEFAULT_MODEL

    @model_options = MODEL_OPTIONS
    @default_model = DEFAULT_MODEL
    @universe = current_user.universes.build
  end

  def show
  end

  def new
    @universe = current_user.universes.build
    @model_options = MODEL_OPTIONS
    @default_model = DEFAULT_MODEL
    @selected_model = sanitized_model_choice(params.dig(:universe, :model))
  end

  def create
    @model_options = MODEL_OPTIONS
    @default_model = DEFAULT_MODEL

    # Check if we're saving a generated universe
    if params[:save_universe] == 'true'
      @universe = current_user.universes.build(
        name: params[:name]
      )

      if @universe.save
        # Parse and save the full data
        full_data = JSON.parse(params[:full_data])

        # Create a default chapter and scene
        chapter = @universe.chapters.create!(name: "Chapter 1")
        scene = chapter.scenes.create!(name: "Scene 1")

        # Create characters
        full_data['characters']&.each do |char_data|
          @universe.characters.create!(
            name: char_data['name'],
            description: char_data['description']
          )
        end

        # Create locations
        full_data['locations']&.each do |loc_data|
          @universe.locations.create!(
            name: loc_data['name'],
            description: loc_data['description']
          )
        end

        # Create beats in the scene
        full_data['beats']&.each do |beat_data|
          scene.beats.create!(
            title: beat_data['title'],
            description: beat_data['description']
          )
        end

        redirect_to @universe, notice: 'Universe was successfully created!'
      else
        redirect_to root_path, alert: 'Failed to save universe.'
      end
      return
    end

    # Otherwise, we're generating a new universe from a prompt
    prompt = params.dig(:universe, :prompt)
    selected_model = sanitized_model_choice(params.dig(:universe, :model))
    @selected_model = selected_model

    unless prompt.present?
      redirect_to root_path, alert: 'Please enter a story prompt.'
      return
    end

    begin
      # Call OpenRouter API to generate story content
      api_response = call_openrouter_api(prompt, selected_model)

      # Store in session and redirect to index for ChatGPT-style display
      session[:api_response] = api_response
      session[:user_prompt] = prompt
      session[:selected_model] = selected_model
      redirect_to authenticated_root_path

    rescue => e
      Rails.logger.error "Error in create: #{e.message}"
      redirect_to authenticated_root_path, alert: "Failed to generate universe: #{e.message}"
    end
  end

  def edit
    @model_options = MODEL_OPTIONS
    @selected_model = DEFAULT_MODEL
  end

  def update
    if @universe.update(universe_params)
      redirect_to @universe, notice: 'Universe was successfully updated!'
    else
      @model_options = MODEL_OPTIONS
      @selected_model = DEFAULT_MODEL
      render :edit
    end
  end

  def regenerate
    @model_options = MODEL_OPTIONS
    selected_model = sanitized_model_choice(params[:model])

    begin
      # Build context from existing universe elements
      context_prompt = build_regeneration_prompt(@universe)

      # Call OpenRouter API with the context
      api_response = call_openrouter_api_for_regeneration(context_prompt, selected_model, @universe)

      # Update the universe with the regenerated content
      if api_response['characters'] && api_response['locations'] && api_response['beats']
        ActiveRecord::Base.transaction do
          @universe.update!(name: api_response['title'] || @universe.name)

          # Get or create default chapter and scene
          chapter = @universe.chapters.first || @universe.chapters.create!(name: "Chapter 1")
          scene = chapter.scenes.first || chapter.scenes.create!(name: "Scene 1")

          # Clear and recreate characters
          @universe.characters.destroy_all
          api_response['characters'].each do |char_data|
            @universe.characters.create!(
              name: char_data['name'],
              description: char_data['description']
            )
          end

          # Clear and recreate locations
          @universe.locations.destroy_all
          api_response['locations'].each do |loc_data|
            @universe.locations.create!(
              name: loc_data['name'],
              description: loc_data['description']
            )
          end

          # Clear and recreate beats
          scene.beats.destroy_all
          api_response['beats'].each do |beat_data|
            scene.beats.create!(
              title: beat_data['title'],
              description: beat_data['description']
            )
          end
        end

        redirect_to @universe, notice: 'Universe was successfully regenerated!'
      else
        redirect_to edit_universe_path(@universe), alert: 'Failed to regenerate universe.'
      end

    rescue => e
      Rails.logger.error "Error regenerating universe: #{e.message}"
      redirect_to edit_universe_path(@universe), alert: "Failed to regenerate: #{e.message}"
    end
  end

  def destroy
    @universe.destroy
    redirect_to universes_url, notice: 'Universe was successfully deleted.'
  end

  private

  def set_universe
    @universe = current_user.universes.find(params[:id])
  end

  def universe_params
    params.require(:universe).permit(:name)
  end

  def call_openrouter_api(user_prompt, model_choice)
    Rails.logger.info "🚀 Calling OpenRouter API with user prompt: #{user_prompt}"
    Rails.logger.info "🤖 Using model: #{model_choice}"

    # Build the expanded prompt with the user's input
    expanded_prompt = <<~PROMPT
      #{user_prompt}

      The text above is USER PROMPT.
      AI INSTRUCTIONS:
      Your task is to expand the USER PROMPT into a continuous story with 4 detailed beats. Each beat must be long-form—target 1,950 to 2,000 characters per beat—and under no circumstances end a beat below 1,900 characters. Expand with sensory detail, character thoughts, environmental texture, and narrative continuity so the length requirement is satisfied while keeping the story coherent. Ensure that you are consistent amongst each beat as each beat is independent of each other, and you must do the job of linking them by repeating descriptions of Characters, Locations, and Objects exactly the same in between the beats of the same story. Maintain consistent characters, objects, and locations across all beats to create a unified cinematic feel. For example if the [USER PROMPT] is "Daniel goes to get some water in a truck", you can identify at minimum one character, Daniel, that becomes [CHARACTER 01], you can identify a location, although it is not clear, so you make one up that is appropriate and has water and it becomes [LOCATION 01], and then we have a minimum of one object, the truck, which becomes [OBJECT 01]. If there are multiple characters, locations and objects, you can add as appropriate, under the grouping headers of [CHARACTER DEFINITIONS], [LOCATION DEFINITIONS], [OBJECT DEFINITIONS]. For the beats, understand the USER PROMPT, and make an action sequence across 4 beats utilizing the appropriate recall tag. For example if Beat 1 uses Daniel and truck, then recall under the [CHARACTER DEFINITIONS] and [OBJECT DEFINITIONS] the description and use it exactly the same across the 4 beats (unless there's a reason to change that state).

      First understand what the user prompt is asking. Is it about someone? Is it about something? Is it about a location? Is it about an animal? Consider the purpose of the user prompt and see how you can visualize their text in 4 beats, with instructions on how to proceed below.

      Then assess the user prompt to identify characters, objects, locations, and fill in the [CHARACTER DEFINITIONS], [OBJECT DEFINITIONS], [LOCATION DEFINITIONS]. These will be headers that I will parse out the content in between them to various locations. You are now ready to generate the beats. Note if the user prompt could contain action scenes between humans, non-humans, animals, etc. These can all be [CHARACTER DEFINITIONS], so an alien or an animal would be described as a character. If the user prompt does not have a character, then perhaps it has an object or a location. Then therefore do not fill in a character, and focus the four beats on a cinematic shot of an object or a location. Often the user may have multiple characters, objects and locations. For example only: "The black haired woman in a wedding dress is pushed out of the door by another woman in a black dress. The woman in the wedding dress is caught by ravens as the plane explodes". Here we have multiple characters, the woman in white wedding dress, the woman in black wedding dress, and the ravens. We also have the location, sky and air; and we have the objects, plane, interior of plane. In this example, you would then use the four beats you have to visualize this dramatic scene, while retaining the same characters location and object definitions throughout each beat.

      Each beat that you generate needs to be processed independently by a video generator API, and the video and generator will be processing each one separately, so you need to ensure that the beats you create have a common look and feel, and ensure consistent location, object and character definitions are used. Ensure that you are repeating all relevant definitions in each beat, not saying "refer to" or "same as", but actually writing the details all out and details must be repeated in each beat.

      The JSON summary you return must contain the exact same beat text in each `beats[i].description` field as the prose you wrote above—no abridgement or summarisation. Copy the full beat paragraphs verbatim into the JSON so downstream systems receive the same rich detail.

      YOU MUST follow this structure EXACTLY. Use the specified headers.

      Also, return a JSON object at the end with this structure for database storage:
      {
        "title": "[Derive a title from the story]",
        "description": "[Brief summary of the story]",
        "characters": [{"name": "[Character Name]", "description": "[Full description]", "role": "protagonist/antagonist/supporting"}],
        "locations": [{"name": "[Location Name]", "description": "[Full description]", "location_type": "setting/landmark/building"}],
        "beats": [{"title": "Beat 1", "description": "[Beat 1 content]", "order_index": 1}]
      }
    PROMPT

    response = HTTParty.post(
      'https://openrouter.ai/api/v1/chat/completions',
      headers: {
        'Authorization' => "Bearer #{ENV['OPENROUTER_API_KEY']}",
        'Content-Type' => 'application/json',
        'HTTP-Referer' => request.base_url,
        'X-Title' => 'Universe Generator'
      },
      body: {
        model: model_choice,
        messages: [
          {
            role: 'system',
            content: 'You are a cinematic story assistant. Follow the exact format provided in the prompt. Generate detailed CHARACTER DEFINITIONS, LOCATION DEFINITIONS, OBJECT DEFINITIONS, and 4 BEATS as specified. At the end, also provide a JSON summary for database storage.'
          },
          {
            role: 'user',
            content: expanded_prompt
          }
        ],
        max_tokens: 9000
      }.to_json
    )

    Rails.logger.info "📡 API Response Status: #{response.code}"

    if response.success?
      content = response.parsed_response.dig('choices', 0, 'message', 'content')

      # Try to extract JSON from the response
      json_match = content.match(/\{[\s\S]*\}/)
      if json_match
        parsed_content = JSON.parse(json_match[0])
      else
        # Fallback: create a basic structure from the text
        parsed_content = {
          'title' => user_prompt.truncate(50),
          'description' => "Generated from: #{user_prompt}",
          'full_response' => content,
          'characters' => [],
          'locations' => [],
          'beats' => []
        }
      end

      # Store the full response for display
      parsed_content['full_response'] = content
      parsed_content
    else
      Rails.logger.error "❌ API request failed: #{response.code} - #{response.message}"
      Rails.logger.error "❌ Response body: #{response.body}"
      raise "API request failed: #{response.code} - #{response.message}"
    end
  end

  def sanitized_model_choice(raw_choice)
    return DEFAULT_MODEL unless raw_choice.present?
    MODEL_OPTIONS.key?(raw_choice) ? raw_choice : DEFAULT_MODEL
  end

  def build_regeneration_prompt(universe)
    "Regenerate content for universe: #{universe.name}"
  end

  def call_openrouter_api_for_regeneration(context_prompt, model_choice, universe)
    call_openrouter_api(context_prompt, model_choice)
  end
end
