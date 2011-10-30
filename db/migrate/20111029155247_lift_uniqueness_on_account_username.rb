class LiftUniquenessOnAccountUsername < ActiveRecord::Migration
  def self.up
    remove_index :accounts,
      :name => :index_accounts_on_username_and_type
    add_index :accounts, [ :username, :type ], :unique => false
  end

  def self.down
    remove_index :accounts, [ :username, :type ]
    add_index :accounts, [ :username, :type ], :unique => true,
      :name => :index_external_accounts_on_uid_and_type
  end
end
