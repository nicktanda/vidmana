class AddRoleToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :role, :string
  end
end
