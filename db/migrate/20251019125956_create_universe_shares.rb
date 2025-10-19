class CreateUniverseShares < ActiveRecord::Migration[8.0]
  def change
    create_table :universe_shares do |t|
      t.references :universe, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :permission_level, null: false

      t.timestamps
    end

    add_index :universe_shares, [:universe_id, :user_id], unique: true
  end
end
