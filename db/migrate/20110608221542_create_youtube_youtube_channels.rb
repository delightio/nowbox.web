class CreateYoutubeYoutubeChannels < ActiveRecord::Migration
  def self.up
    create_table :youtube_youtube_channels, :id => false do |t|
      t.integer :account_id
      t.integer :channel_id
    end
  end

  def self.down
    remove_table :youtube_youtube_channels
  end
end
