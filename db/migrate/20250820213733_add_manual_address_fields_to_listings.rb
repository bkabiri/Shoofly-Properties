class AddManualAddressFieldsToListings < ActiveRecord::Migration[7.0]
  def change
    add_column :listings, :address_line1, :string
    add_column :listings, :address_line2, :string
    add_column :listings, :postcode,      :string
    add_column :listings, :city,          :string
  end
end