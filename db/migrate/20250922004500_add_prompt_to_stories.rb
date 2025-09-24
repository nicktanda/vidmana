class AddPromptToStories < ActiveRecord::Migration[8.0]
  def change
    add_column :stories, :prompt, :text
  end
end
