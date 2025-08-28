class CreateAgencyMemberships < ActiveRecord::Migration[7.0]
  def change
    create_table :agency_memberships do |t|
      t.bigint :agency_id
      t.bigint :user_id
      t.string :role

      t.timestamps
    end
    add_index :agency_memberships, :agency_id
    add_index :agency_memberships, :user_id
  end
end
