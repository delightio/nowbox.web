class RenameExternalAccountTableAccount < ActiveRecord::Migration
  def self.up
    rename_table :external_accounts, :accounts
  end

  def self.down
    rename_table :accounts, :external_accounts
  end
end
