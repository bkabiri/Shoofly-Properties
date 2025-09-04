# db/migrate/20250903000110_create_messages.rb
class CreateMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :user,         null: false, foreign_key: true
      t.text       :body,         null: false
      t.datetime   :read_at
      t.timestamps
    end
    add_index :messages, :created_at
  end
end