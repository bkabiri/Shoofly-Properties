# db/migrate/20250824230936_fix_favorites_table.rb
class FixFavoritesTable < ActiveRecord::Migration[7.0]
  def up
    # Case A: old British table exists → rename it
    if table_exists?(:favourites)
      rename_table :favourites, :favorites

    # Case B: British table doesn't exist, but US one already does → nothing to do
    elsif table_exists?(:favorites)
      say "favorites table already present, skipping create"

    # Case C: neither table exists → create it
    else
      create_table :favorites do |t|
        t.references :user,    null: false, foreign_key: true
        t.references :listing, null: false, foreign_key: true
        t.timestamps
      end
      add_index :favorites, [:user_id, :listing_id], unique: true, name: "index_favorites_on_user_and_listing"
    end
  end

  def down
    # Prefer removing the US table on rollback (simple + deterministic)
    if table_exists?(:favorites)
      drop_table :favorites
    elsif table_exists?(:favourites)
      drop_table :favourites
    end
  end
end