class AddPopulatedAtToExternalAccounts < ActiveRecord::Migration
  def self.up
    add_column :external_accounts, :populated_at, :datetime
  end

  def self.down
    remove_column :external_accounts, :populated_at
  end
end
