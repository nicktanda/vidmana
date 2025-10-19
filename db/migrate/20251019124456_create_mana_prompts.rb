class CreateManaPrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :mana_prompts do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.text :content, null: false

      t.timestamps
    end
  end
end
