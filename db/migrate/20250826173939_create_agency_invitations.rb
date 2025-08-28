class CreateAgencyInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :agency_invitations do |t|
      t.bigint :agency_id
      t.string :email
      t.string :role
      t.string :token
      t.datetime :accepted_at

      t.timestamps
    end
    add_index :agency_invitations, :agency_id
    add_index :agency_invitations, :email
    add_index :agency_invitations, :token
  end
end
