class AddEstateAgentNameToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :estate_agent_name, :string
  end
end
