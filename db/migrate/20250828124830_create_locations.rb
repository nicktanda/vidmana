class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.text :description
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
