class AddUserToExternalAccount < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :user_id, :integer
  end

  def self.down
    remove_column :external_accounts, :user_id
  end
end
