# db/migrate/20240908000100_create_promotion_codes.rb
class CreatePromotionCodes < ActiveRecord::Migration[7.0]
  def change
    create_table :promotion_codes do |t|
      t.string   :code, null: false
      t.string   :kind, null: false, default: "free_listing"  # future-proof
      t.integer  :usage_limit, null: false, default: 1
      t.integer  :used_count,  null: false, default: 0
      t.datetime :starts_at
      t.datetime :expires_at
      t.boolean  :active, null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :promotion_codes, :code, unique: true
  end
end