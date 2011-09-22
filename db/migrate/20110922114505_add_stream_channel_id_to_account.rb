class AddStreamChannelIdToAccount < ActiveRecord::Migration
  def self.up
    add_column :accounts, :stream_channel_id, :integer
  end

  def self.down
    remove_column :accounts, :stream_channel_id
  end
end
