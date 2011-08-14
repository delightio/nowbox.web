class AddUserChannelIdsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :favorite_channel_id, :integer, :null => false
    add_column :users, :history_channel_id, :integer, :null => false
    add_column :users, :queue_channel_id, :integer, :null => false
  end

  def self.down
    remove_column :users, :favorite_channel_id
    remove_column :users, :history_channel_id
    remove_column :users, :queue_channel_id
  end
end
