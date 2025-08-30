class CreatePlans < ActiveRecord::Migration[7.0]
  def change
    create_table :plans do |t|
      t.string  :code, null: false, index: { unique: true } # "priv_starter_once"
      t.string  :name, null: false                           # "Private Starter (3 months)"
      t.string  :kind, null: false                           # "one_time" or "subscription"
      t.integer :amount_cents, null: false                   # 1000 for £10.00
      t.string  :currency, null: false, default: "gbp"
      t.string  :interval                                   # "month" if subscription, else nil
      t.integer :duration_months                            # 3 for the £10 “3 months access”
      t.boolean :gives_premium, default: false
      t.integer :premium_weeks                              # e.g. 2
      t.timestamps
    end
  end
endcreate_payments