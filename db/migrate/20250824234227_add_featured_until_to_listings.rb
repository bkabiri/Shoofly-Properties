class AddFeaturedUntilToListings < ActiveRecord::Migration[7.0]
  def change
    add_column :listings, :featured_until, :datetime
    add_index  :listings, :featured_until
  end
end