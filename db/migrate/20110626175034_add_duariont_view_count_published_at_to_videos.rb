class AddDuariontViewCountPublishedAtToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :duration, :decimal
    add_column :videos, :view_count, :integer
    add_column :videos, :published_at, :datetime
  end

  def self.down
    remove_column :videos, :duartion
    remove_column :videos, :view_count
    remove_column :videos, :published_at
  end
end
