class AddMultipleManaPrompts < ActiveRecord::Migration[8.0]
  def change
    # Add name to mana_prompts for identification
    add_column :mana_prompts, :name, :string, null: false, default: "Default Prompt"

    # Remove unique constraint, allow multiple prompts per user
    remove_index :mana_prompts, :user_id
    add_index :mana_prompts, :user_id

    # Add mana_prompt reference to universes
    add_reference :universes, :mana_prompt, null: true, foreign_key: true
  end
end
