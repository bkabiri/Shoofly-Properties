class AddGuidePriceToListings < ActiveRecord::Migration[7.0]
  def change
    add_column :listings, :guide_price, :decimal, precision: 12, scale: 2
  end
end