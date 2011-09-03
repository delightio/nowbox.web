class AddIndexToMentionsVideos < ActiveRecord::Migration
  def self.up
    add_index(:mentions_videos, [:mention_id, :video_id], :unique => true)
  end

  def self.down
    remove_index :mentions_videos, :column => [:mention_id, :video_id]
  end
end
