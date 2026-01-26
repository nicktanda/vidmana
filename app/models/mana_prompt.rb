class ManaPrompt < ApplicationRecord
  AVAILABLE_MODELS = [
    ['Grok 4 Fast', 'x-ai/grok-4-fast'],
    ['Grok 3 Mini', 'x-ai/grok-3-mini'],
    ['Qwen 2.5', 'qwen/qwen-2.5-72b-instruct'],
    ['Qwen 3 Coder', 'qwen/qwen3-coder']
  ].freeze

  belongs_to :user
  has_many :universes, dependent: :nullify

  validates :content, presence: true
  validates :name, presence: true
  validates :model, presence: true, inclusion: { in: AVAILABLE_MODELS.map(&:last) }

  def model_display_name
    AVAILABLE_MODELS.find { |name, value| value == model }&.first || model
  end

  DEFAULT_PROMPT = <<~PROMPT.freeze
    {USER_PROMPT}

    The text above is USER PROMPT.
    AI INSTRUCTIONS:
    Your task is to expand the USER PROMPT into a continuous story with 4 detailed scenes. Each scene must be long-form—target 1,950 to 2,000 characters per scene—and under no circumstances end a scene below 1,900 characters. Expand with sensory detail, character thoughts, environmental texture, and narrative continuity so the length requirement is satisfied while keeping the story coherent. Ensure that you are consistent amongst each scene as each scene is independent of each other, and you must do the job of linking them by repeating descriptions of Characters, Locations, and Objects exactly the same in between the scenes of the same story. Maintain consistent characters, objects, and locations across all scenes to create a unified cinematic feel.

    For example if the [USER PROMPT] is "Daniel goes to get some water in a truck", you can identify at minimum one character, Daniel, that becomes [CHARACTER 01], you can identify a location, although it is not clear, so you make one up that is appropriate and has water and it becomes [LOCATION 01], and then we have a minimum of one object, the truck, which becomes [OBJECT 01]. If there are multiple characters, locations and objects, you can add as appropriate, under the grouping headers of [CHARACTER DEFINITIONS], [LOCATION DEFINITIONS], [OBJECT DEFINITIONS]. For the scenes, understand the USER PROMPT, and make an action sequence across 4 scenes utilizing the appropriate recall tag. For example if Scene 1 uses Daniel and truck, then recall under the [CHARACTER DEFINITIONS] and [OBJECT DEFINITIONS] the description and use it exactly the same across the 4 scenes (unless there's a reason to change that state).

    First understand what the user prompt is asking. Is it about someone? Is it about something? Is it about a location? Is it about an animal? Consider the purpose of the user prompt and see how you can visualize their text in 4 scenes, with instructions on how to proceed below.

    Then assess the user prompt to identify characters, objects, locations, and fill in the [CHARACTER DEFINITIONS], [OBJECT DEFINITIONS], [LOCATION DEFINITIONS]. These will be headers that I will parse out the content in between them to various locations. You are now ready to generate the scenes. Note if the user prompt could contain action scenes between humans, non-humans, animals, etc. These can all be [CHARACTER DEFINITIONS], so an alien or an animal would be described as a character. If the user prompt does not have a character, then perhaps it has an object or a location. Then therefore do not fill in a character, and focus the four scenes on a cinematic shot of an object or a location. Often the user may have multiple characters, objects and locations. For example only: "The black haired woman in a wedding dress is pushed out of the door by another woman in a black dress. The woman in the wedding dress is caught by ravens as the plane explodes". Here we have multiple characters, the woman in white wedding dress, the woman in black wedding dress, and the ravens. We also have the location, sky and air; and we have the objects, plane, interior of plane. In this example, you would then use the four scenes you have to visualize this dramatic scene, while retaining the same characters location and object definitions throughout each scene.

    Each scene that you generate needs to be processed independently by a video generator API, and the video generator will be processing each one separately, so you need to ensure that the scenes you create have a common look and feel, and ensure consistent location, object and character definitions are used. Ensure that you are repeating all relevant definitions in each scene, not saying "refer to" or "same as", but actually writing the details all out and details must be repeated in each scene.

    The JSON you return must contain the exact same scene text in each `scenes[i].description` field as the prose you wrote above—no abridgement or summarisation. Copy the full scene paragraphs verbatim into the JSON so downstream systems receive the same rich detail.

    YOU MUST follow this structure EXACTLY. Use the specified headers.

    Return ONLY a JSON object with this structure for database storage:
    {
      "title": "[Derive a title from the story]",
      "description": "[Brief summary of the story]",
      "characters": [{"name": "[Character Name]", "description": "[Full description]", "role": "protagonist"}],
      "locations": [{"name": "[Location Name]", "description": "[Full description]", "location_type": "setting"}],
      "scenes": [{"name": "Scene 1", "description": "[Scene 1 content - must be 1900+ characters]"}]
    }
  PROMPT
end
