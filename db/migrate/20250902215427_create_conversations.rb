# db/migrate/20250903000100_create_conversations.rb
class CreateConversations < ActiveRecord::Migration[7.0]
  def change
    create_table :conversations do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :buyer,  null: false, foreign_key: { to_table: :users }
      t.references :seller, null: false, foreign_key: { to_table: :users }
      t.datetime   :last_message_at
      t.index [:listing_id, :buyer_id, :seller_id], unique: true, name: "idx_convo_unique_triplet"
      t.timestamps
    end
  end
end