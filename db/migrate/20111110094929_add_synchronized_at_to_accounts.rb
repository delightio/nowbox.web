class AddSynchronizedAtToAccounts < ActiveRecord::Migration
  def self.up
    add_column :accounts, :synchronized_at, :datetime
  end

  def self.down
    remove_column :accounts, :synchronized_at
  end
end
