class AddIndexToVideos < ActiveRecord::Migration
  def self.up
    add_index(:videos, [:external_id, :source], :unique => true)
  end

  def self.down
    remove_index :videos, :column => [:external_id, :source]
  end
end
