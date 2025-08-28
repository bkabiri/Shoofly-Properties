class AddAgentFieldsToUsers < ActiveRecord::Migration[7.0]
  def change
    # Office address (detailed)
    add_column :users, :office_address_line1, :string
    add_column :users, :office_address_line2, :string
    add_column :users, :office_postcode,       :string
    add_column :users, :office_city,           :string
    add_column :users, :office_county,         :string

    # Contact numbers
    add_column :users, :landline_phone, :string
    add_column :users, :mobile_phone,   :string
  end
end