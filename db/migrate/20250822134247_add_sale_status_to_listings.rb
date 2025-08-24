class AddSaleStatusToListings < ActiveRecord::Migration[7.0]
  def change
    add_column :listings, :sale_status, :integer, default: 0, null: false
    add_index  :listings, :sale_status
  end
end