class AddVideoStartToEvents < ActiveRecord::Migration
  def self.up
    add_column :events, :video_start, :decimal, :default => 0.0, :null => false
  end

  def self.down
    drop_column :events, :video_start
  end
end
