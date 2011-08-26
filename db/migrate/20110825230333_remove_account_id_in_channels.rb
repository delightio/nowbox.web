class RemoveAccountIdInChannels < ActiveRecord::Migration
  def self.up
    remove_column :channels, :account_id
  end

  def self.down
    add_column :channels, :account_id, :integer
  end
end
