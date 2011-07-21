class AddBlacklistedAtToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :blacklisted_at, :datetime
  end

  def self.down
    remove_column :videos, :blacklisted_at
  end
end
