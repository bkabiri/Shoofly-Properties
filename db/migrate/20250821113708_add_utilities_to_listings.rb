class AddUtilitiesToListings < ActiveRecord::Migration[7.0]
  def change
    add_column :listings, :broadband, :string
    add_column :listings, :electricity_supplier, :string
    add_column :listings, :gas_supplier, :string
  end
end
