class CreatePayments < ActiveRecord::Migration[7.0]
  def change
    create_table :payments do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :listing, null: true,  foreign_key: true
      t.references :plan,    null: false, foreign_key: true

      t.string  :stripe_session_id, null: false, index: true
      t.string  :stripe_payment_intent_id
      t.string  :stripe_subscription_id
      t.integer :amount_cents, null: false
      t.string  :currency,     null: false
      t.string  :status,       null: false, default: "pending" # pending, paid, failed
      t.jsonb   :stripe_payload
      t.timestamps
    end
  end
end