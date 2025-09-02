class CreateTickets < ActiveRecord::Migration[7.0]
  def change
    create_table :tickets do |t|
      t.string  :subject,  null: false
      t.text    :body

      # enums: 0=open, 1=pending, 2=resolved, 3=closed
      t.integer :status,   null: false, default: 0
      # enums: 0=low, 1=normal, 2=high, 3=urgent
      t.integer :priority, null: false, default: 1

      t.references :requester,   foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :tickets, :status
    add_index :tickets, :priority
    add_index :tickets, :updated_at
  end
end