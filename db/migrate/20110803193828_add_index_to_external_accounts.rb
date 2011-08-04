class AddIndexToExternalAccounts < ActiveRecord::Migration
  def self.up
    add_index(:external_accounts, [:uid, :type], :unique => true)
  end

  def self.down
    remove_index :external_accounts, :column => [:uid, :type]
  end
end
