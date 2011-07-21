class AddPublishedAtToMentions < ActiveRecord::Migration
  def self.up
    add_column :mentions, :published_at, :datetime
  end

  def self.down
    remove_column :mentions, :published_at
  end
end
