class AddUsernameToAccount < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :username, :string
  end

  def self.down
    remove_column :external_accounts, :username
  end
end
