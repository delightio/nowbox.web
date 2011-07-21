class AddPopulatedAtToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :populated_at, :datetime
  end

  def self.down
    remove_column :videos, :populated_at
  end
end
