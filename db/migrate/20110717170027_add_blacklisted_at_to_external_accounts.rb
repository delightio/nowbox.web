class AddBlacklistedAtToExternalAccounts < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :blacklisted_at, :datetime
  end

  def self.down
    drop_colum :external_accounts, :blacklisted_at
  end
end
