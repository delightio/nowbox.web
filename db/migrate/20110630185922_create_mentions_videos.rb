class CreateMentionsVideos < ActiveRecord::Migration
  def self.up
    create_table :mentions_videos, :id => false do |t|
      t.integer :mention_id
      t.integer :video_id
    end
  end

  def self.down
    remove_table :mentions_videos
  end
end
