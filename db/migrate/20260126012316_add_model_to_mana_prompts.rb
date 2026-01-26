class AddModelToManaPrompts < ActiveRecord::Migration[8.0]
  def change
    add_column :mana_prompts, :model, :string, null: false, default: 'x-ai/grok-4-fast'
  end
end
