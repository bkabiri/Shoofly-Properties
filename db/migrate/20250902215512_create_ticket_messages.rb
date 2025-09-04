# db/migrate/20250903000120_create_ticket_messages.rb
class CreateTicketMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :ticket_messages do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.text       :body,   null: false
      t.timestamps
    end
  end
end