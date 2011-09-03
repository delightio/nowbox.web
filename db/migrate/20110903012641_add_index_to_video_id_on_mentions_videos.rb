class AddIndexToVideoIdOnMentionsVideos < ActiveRecord::Migration
  def self.up
    add_index :mentions_videos, :video_id
  end

  def self.down
    remove_index :mentions_videos, :video_id
  end
end
