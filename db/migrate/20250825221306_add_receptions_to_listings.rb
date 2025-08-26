class AddReceptionsToListings < ActiveRecord::Migration[7.0]
  def change
    add_column :listings, :receptions, :integer
  end
end
