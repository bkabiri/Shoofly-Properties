class AddEstateAgentRoleToUsers < ActiveRecord::Migration[7.0]
  def up
    # Move existing admins (currently role=2) to 3
    execute "UPDATE users SET role = 3 WHERE role = 2"
  end

  def down
    # Rollback: move them back 3 -> 2
    execute "UPDATE users SET role = 2 WHERE role = 3"
  end
end