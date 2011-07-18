class AddBlacklistedAtToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :blacklisted_at, :datetime
  end

  def self.down
    drop_colum :videos, :blacklisted_at
  end
end
