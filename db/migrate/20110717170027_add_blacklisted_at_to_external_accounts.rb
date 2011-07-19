class AddBlacklistedAtToExternalAccounts < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :blacklisted_at, :datetime
  end

  def self.down
    remove_column :external_accounts, :blacklisted_at
  end
end
