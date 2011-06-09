class AddCredentialsToExternalAccount < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :credentials, :text
  end

  def self.down
    remove_column :external_accounts, :credentials
  end
end
