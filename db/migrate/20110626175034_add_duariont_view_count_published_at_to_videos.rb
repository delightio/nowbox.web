class AddDuariontViewCountPublishedAtToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :duration, :decimal
    add_column :videos, :view_count, :integer
    add_column :videos, :published_at, :datetime
  end

  def self.down
    drop_colum :videos, :duartion
    drop_colum :videos, :view_count
    drop_colum :videos, :published_at
  end
end
