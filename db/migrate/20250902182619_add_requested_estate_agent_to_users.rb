# db/migrate/20250902193000_add_requested_estate_agent_to_users.rb
class AddRequestedEstateAgentToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :requested_estate_agent, :boolean, null: false, default: false
    add_index  :users, :requested_estate_agent
  end
end