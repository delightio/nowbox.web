class AddIdentityIdIndexToAccounts < ActiveRecord::Migration
  def self.up
    add_index :accounts, :identity_id
  end

  def self.down
    remove_index :accounts, :identity_id
  end
end
