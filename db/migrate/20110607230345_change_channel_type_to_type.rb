# 20110607230345_change_channel_type_to_type.rb
class ChangeChannelTypeToType < ActiveRecord::Migration
  def self.up
    rename_column :channels, :channel_type, :type
  end
  def self.down
    rename_column :channels, :type, :channel_type
  end
end
