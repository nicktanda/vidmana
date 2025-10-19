class AddPromptToUniverses < ActiveRecord::Migration[8.0]
  def change
    add_column :universes, :prompt, :text
  end
end
