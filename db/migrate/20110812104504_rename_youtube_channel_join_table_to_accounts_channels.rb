class RenameYoutubeChannelJoinTableToAccountsChannels < ActiveRecord::Migration
  def self.up
    rename_table :youtube_youtube_channels, :accounts_channels
  end

  def self.down
    rename_table :accounts_channels, :youtube_youtube_channels
  end
end
