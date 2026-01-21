class UniversesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_universe, only: [:show, :edit, :update, :destroy, :regenerate]
  before_action :authorize_view!, only: [:show]
  before_action :authorize_edit!, only: [:edit, :update, :destroy, :regenerate]

  MODEL_OPTIONS = {
    'x-ai/grok-4-fast' => 'Grok 4 Fast',
    'x-ai/grok-3-mini' => 'Grok 3 Mini',
    'qwen/qwen-2.5-72b-instruct' => 'Qwen 2.5',
    'qwen/qwen3-coder' => 'Qwen 3 Coder'
  }.freeze

  DEFAULT_MODEL = 'x-ai/grok-4-fast'.freeze

  def index
    # Prevent browser from caching form state
    response.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate'
    response.headers['Pragma'] = 'no-cache'
    response.headers['Expires'] = '0'

    # Get owned universes and shared universes
    @owned_universes = current_user.universes.order(created_at: :desc)
    @shared_universes = current_user.shared_universes.order(created_at: :desc)
    @universes = @owned_universes # Keep for backward compatibility

    # For ChatGPT-style interface: show API response if available
    @api_response = session.delete(:api_response)
    @user_prompt = session.delete(:user_prompt)
    @selected_model = session.delete(:selected_model) || DEFAULT_MODEL

    @model_options = MODEL_OPTIONS
    @default_model = DEFAULT_MODEL
    @universe = current_user.universes.build
  end

  def show
    # Get available users to share with (exclude owner and already shared users)
    if @universe.user_id == current_user.id
      already_shared_user_ids = @universe.universe_shares.pluck(:user_id)
      @available_users = User.where.not(id: [current_user.id] + already_shared_user_ids).order(:name)
    end
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
        name: params[:name],
        prompt: params[:prompt]
      )

      if @universe.save
        # Parse and save the full data
        full_data = JSON.parse(params[:full_data])

        # Create characters
        full_data['characters']&.each do |char_data|
          @universe.characters.create!(
            name: char_data['name'],
            description: char_data['description'],
            role: char_data['role']
          )
        end

        # Create locations
        full_data['locations']&.each do |loc_data|
          @universe.locations.create!(
            name: loc_data['name'],
            description: loc_data['description'],
            location_type: loc_data['location_type']
          )
        end

        # Create chapters
        full_data['chapters']&.each do |chapter_data|
          @universe.chapters.create!(
            name: chapter_data['name'],
            description: chapter_data['description']
          )
        end

        # Create beats directly on universe (extract from scenes in API response)
        beat_order = 0
        full_data['chapters']&.each do |chapter_data|
          chapter_data['scenes']&.each do |scene_data|
            # If scene has beats, create them on the universe
            scene_data['beats']&.each do |beat_data|
              beat_order += 1
              @universe.beats.create!(
                title: beat_data['title'],
                description: beat_data['description'],
                order_index: beat_data['order_index'] || beat_order
              )
            end
            # If no beats but scene has content, create a beat from the scene
            if scene_data['beats'].blank? && scene_data['description'].present?
              beat_order += 1
              @universe.beats.create!(
                title: scene_data['name'],
                description: scene_data['description'],
                order_index: beat_order
              )
            end
          end
        end

        redirect_to @universe, notice: 'Universe was successfully created!'
      else
        redirect_to root_path, alert: 'Failed to save universe.'
      end
      return
    end

    # Otherwise, we're generating a new universe from a prompt
    user_prompt = params.dig(:universe, :prompt)
    selected_model = sanitized_model_choice(params.dig(:universe, :model))
    @selected_model = selected_model

    unless user_prompt.present?
      redirect_to root_path, alert: 'Please enter a story prompt.'
      return
    end

    begin
      # Call OpenRouter API to generate story content
      api_response = call_openrouter_api(user_prompt, selected_model)

      # Store prompt in api_response so it gets saved later
      api_response['prompt'] = user_prompt

      # Store in session and redirect to index for ChatGPT-style display
      session[:api_response] = api_response
      session[:user_prompt] = user_prompt
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
      # Use the prompt from params if provided, otherwise use existing universe prompt
      user_prompt = params[:prompt].present? ? params[:prompt] : @universe.prompt

      # Update the universe name and prompt
      @universe.update(
        name: params[:name].present? ? params[:name] : @universe.name,
        prompt: params[:prompt].present? ? params[:prompt] : @universe.prompt
      )

      # Call OpenRouter API with the prompt
      api_response = call_openrouter_api(user_prompt, selected_model)

      # Update the universe with the regenerated content
      if api_response['characters'] && api_response['locations'] && api_response['chapters']
        ActiveRecord::Base.transaction do

          # Clear existing data
          @universe.characters.destroy_all
          @universe.locations.destroy_all
          @universe.chapters.destroy_all
          @universe.beats.destroy_all

          # Create characters
          api_response['characters']&.each do |char_data|
            @universe.characters.create!(
              name: char_data['name'],
              description: char_data['description'],
              role: char_data['role']
            )
          end

          # Create locations
          api_response['locations']&.each do |loc_data|
            @universe.locations.create!(
              name: loc_data['name'],
              description: loc_data['description'],
              location_type: loc_data['location_type']
            )
          end

          # Create chapters
          api_response['chapters']&.each do |chapter_data|
            @universe.chapters.create!(
              name: chapter_data['name'],
              description: chapter_data['description']
            )
          end

          # Create beats directly on universe (extract from scenes in API response)
          beat_order = 0
          api_response['chapters']&.each do |chapter_data|
            chapter_data['scenes']&.each do |scene_data|
              # If scene has beats, create them on the universe
              scene_data['beats']&.each do |beat_data|
                beat_order += 1
                @universe.beats.create!(
                  title: beat_data['title'],
                  description: beat_data['description'],
                  order_index: beat_data['order_index'] || beat_order
                )
              end
              # If no beats but scene has content, create a beat from the scene
              if scene_data['beats'].blank? && scene_data['description'].present?
                beat_order += 1
                @universe.beats.create!(
                  title: scene_data['name'],
                  description: scene_data['description'],
                  order_index: beat_order
                )
              end
            end
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
    # Find universe that user owns or has been shared with
    # Eager load associations to avoid N+1 queries
    @universe = Universe.includes(
      :characters,
      :locations,
      :beats,
      :chapters,
      universe_shares: :user
    ).find(params[:id])
  end

  def authorize_view!
    unless @universe.can_view?(current_user)
      redirect_to authenticated_root_path, alert: "You don't have permission to view this universe."
    end
  end

  def authorize_edit!
    unless @universe.can_edit?(current_user)
      redirect_to @universe, alert: "You don't have permission to edit this universe."
    end
  end

  def universe_params
    params.require(:universe).permit(:name, :prompt)
  end

  def call_openrouter_api(user_prompt, model_choice)
    Rails.logger.info "🚀 Calling OpenRouter API with user prompt: #{user_prompt}"
    Rails.logger.info "🤖 Using model: #{model_choice}"

    # Get the user's ManaPrompt template and replace {USER_PROMPT} with the actual prompt
    mana_prompt_template = current_user.mana_prompt.content
    expanded_prompt = mana_prompt_template.gsub('{USER_PROMPT}', user_prompt)

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
            content: 'You are a cinematic story assistant. Follow the exact format provided in the prompt. Generate detailed CHARACTER DEFINITIONS, LOCATION DEFINITIONS, and 4 SCENES as specified. Return ONLY a valid JSON object for database storage - no additional text before or after the JSON.'
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
      Rails.logger.info "📝 Raw API Response: #{content[0..500]}..." # Log first 500 chars

      # Try to extract JSON from the response - look for last complete JSON object
      json_match = content.match(/\{(?:[^{}]|\{[^{}]*\})*\}/m)

      if json_match
        json_string = json_match[0]

        # Clean up common JSON issues
        json_string = json_string.gsub(/,(\s*[}\]])/, '\1')  # Remove trailing commas
        json_string = json_string.gsub(/\n/, ' ')  # Remove newlines that might break strings

        begin
          parsed_content = JSON.parse(json_string)
          Rails.logger.info "✅ Successfully parsed JSON"

          # If flat structure (scenes or beats at top level), convert to nested chapter structure
          if !parsed_content['chapters']
            Rails.logger.info "🔄 Converting flat structure to nested"

            scenes = if parsed_content['scenes']
              # New format: scenes directly at top level
              parsed_content['scenes'].map do |scene|
                {
                  'name' => scene['name'] || 'Scene',
                  'description' => scene['description'],
                  'beats' => [] # Empty beats array
                }
              end
            elsif parsed_content['beats']
              # Old format: beats at top level (convert to scenes for backward compatibility)
              parsed_content['beats'].map.with_index do |beat, index|
                {
                  'name' => beat['title'] || "Scene #{index + 1}",
                  'description' => beat['description'],
                  'beats' => []
                }
              end
            else
              []
            end

            parsed_content['chapters'] = [{
              'name' => 'Chapter 1',
              'description' => parsed_content['description'] || 'Main story',
              'scenes' => scenes
            }]

            parsed_content.delete('beats')
            parsed_content.delete('scenes')
          end
        rescue JSON::ParserError => e
          Rails.logger.error "❌ JSON Parse Error: #{e.message}"
          Rails.logger.error "❌ Failed JSON string: #{json_string[0..1000]}"

          # Fallback: create a basic structure from the text
          parsed_content = {
            'title' => user_prompt.truncate(50),
            'description' => "Generated from: #{user_prompt}",
            'full_response' => content,
            'characters' => [],
            'locations' => [],
            'chapters' => [{
              'name' => 'Chapter 1',
              'description' => 'Main story',
              'scenes' => []
            }]
          }
        end
      else
        Rails.logger.error "❌ No JSON found in response"
        # Fallback: create a basic structure from the text
        parsed_content = {
          'title' => user_prompt.truncate(50),
          'description' => "Generated from: #{user_prompt}",
          'full_response' => content,
          'characters' => [],
          'locations' => [],
          'chapters' => [{
            'name' => 'Chapter 1',
            'description' => 'Main story',
            'scenes' => [{
              'name' => 'Scene 1',
              'description' => 'Main scene',
              'beats' => []
            }]
          }]
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
end
