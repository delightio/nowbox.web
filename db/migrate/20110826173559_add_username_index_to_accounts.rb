class AddUsernameIndexToAccounts < ActiveRecord::Migration
  def self.up
    add_index :accounts, [:username, :type], :unique => true
  end

  def self.down
    remove_index :accounts, :column => [:username, :type]
  end
end
