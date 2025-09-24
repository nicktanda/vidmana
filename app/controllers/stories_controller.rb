class StoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story, only: [:show, :edit, :update, :destroy]

  def index
    @stories = current_user.stories.order(created_at: :desc)
  end

  def show
  end

  MODEL_OPTIONS = {
    'x-ai/grok-3-mini' => 'Grok 3 Mini',
    'qwen/qwen-2.5-72b-instruct' => 'Qwen 2.5',
    'qwen/qwen3-coder' => 'Qwen 3 Coder'
  }.freeze

  DEFAULT_MODEL = 'x-ai/grok-3-mini'.freeze

  def new
    @story = current_user.stories.build
    @model_options = MODEL_OPTIONS
    @default_model = DEFAULT_MODEL
    @selected_model = sanitized_model_choice(params.dig(:story, :model))
  end

  def create
    @model_options = MODEL_OPTIONS
    @default_model = DEFAULT_MODEL
    # Check if we're saving a generated story
    if params[:save_story] == 'true'
      @story = current_user.stories.build(
        title: params[:title],
        description: params[:description],
        prompt: params[:prompt]
      )

      if @story.save
        # Parse and save the full data (characters, locations, beats)
        full_data = JSON.parse(params[:full_data])

        # Create characters
        full_data['characters']&.each do |char_data|
          @story.characters.create!(
            name: char_data['name'],
            description: char_data['description'],
            role: char_data['role']
          )
        end

        # Create locations
        full_data['locations']&.each do |loc_data|
          @story.locations.create!(
            name: loc_data['name'],
            description: loc_data['description'],
            location_type: loc_data['location_type']
          )
        end

        # Create beats
        full_data['beats']&.each do |beat_data|
          @story.beats.create!(
            title: beat_data['title'],
            description: beat_data['description'],
            order_index: beat_data['order_index']
          )
        end

        redirect_to @story, notice: 'Story was successfully created!'
      else
        redirect_to new_story_path, alert: 'Failed to save story.'
      end
      return
    end

    # Otherwise, we're generating a new story from a prompt
    prompt = params.dig(:story, :prompt)
    selected_model = sanitized_model_choice(params.dig(:story, :model))
    @selected_model = selected_model

    unless prompt.present?
      redirect_to new_story_path, alert: 'Please enter a story prompt.'
      return
    end

    begin
      # Call OpenRouter API to generate story content
      api_response = call_openrouter_api(prompt, selected_model)

      # For now, just display the response in the chat
      @api_response = api_response
      @user_prompt = prompt
      @story = current_user.stories.build  # Initialize @story so form_with doesn't fail
      Rails.logger.info "💡 About to render view with response"
      render :new
      Rails.logger.info "✅ View rendered successfully"

    rescue => e
      Rails.logger.error "❌ Error in create: #{e.message}"
      Rails.logger.error "❌ Backtrace: #{e.backtrace.first(5)}"
      redirect_to new_story_path, alert: "Failed to generate story: #{e.message}"
    end
  end

  def edit
  end

  def update
    if @story.update(story_params)
      redirect_to @story, notice: 'Story was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @story.destroy
    redirect_to stories_url, notice: 'Story was successfully deleted.'
  end

  private

  def set_story
    @story = current_user.stories.find(params[:id])
  end

  def story_params
    params.require(:story).permit(:title, :description, :prompt,
      characters_attributes: [:id, :name, :description, :role, :_destroy],
      locations_attributes: [:id, :name, :description, :location_type, :_destroy],
      beats_attributes: [:id, :title, :description, :order_index, :_destroy])
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
        'X-Title' => 'Story Generator'
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

    if MODEL_OPTIONS.key?(raw_choice)
      raw_choice
    else
      Rails.logger.warn "⚠️ Unknown model selection '#{raw_choice}', falling back to #{DEFAULT_MODEL}"
      DEFAULT_MODEL
    end
  end
end
