class AddOrderIndexToBeats < ActiveRecord::Migration[8.0]
  def change
    add_column :beats, :order_index, :integer
  end
end
