class CreateListings < ActiveRecord::Migration[7.0]
  def change
    create_table :listings do |t|
      t.references :user, null: false, foreign_key: true     # seller/owner

      t.string  :address, null: false
      t.string  :place_id                                # nullable placeholder

      t.integer :property_type, null: false              # enum
      t.integer :bedrooms, null: false, default: 0
      t.integer :bathrooms, null: false, default: 0

      t.decimal :size_value, precision: 10, scale: 2     # optional
      t.string  :size_unit                                # "sq ft", "sqm"

      t.integer :tenure, null: false                     # enum
      t.integer :council_tax_band                        # enum
      t.integer :parking                                 # enum
      t.boolean :garden                                  # optional

      t.string  :title, null: false
      t.text    :description_raw, null: false            # sanitized/plain fallback

      t.integer :status, null: false, default: 0         # enum: draft/published

      t.timestamps
    end

    add_index :listings, :status
    add_index :listings, :property_type
    add_index :listings, :tenure
  end
end