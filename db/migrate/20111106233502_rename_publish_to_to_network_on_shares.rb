class RenamePublishToToNetworkOnShares < ActiveRecord::Migration
  def self.up
    rename_column :shares, :publish_to, :network
  end

  def self.down
    rename_column :shares, :network, :publish_to
  end
end
