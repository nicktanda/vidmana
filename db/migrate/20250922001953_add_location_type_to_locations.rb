class AddLocationTypeToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :location_type, :string
  end
end
