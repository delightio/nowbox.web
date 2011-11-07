class AddChannelToShares < ActiveRecord::Migration
  def self.up
    add_column :shares, :channel_id, :integer
  end

  def self.down
    remove_column :shares, :channel_id
  end
end
