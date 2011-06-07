class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.integer :user_id, :null => false
      t.integer :video_id, :null => false
      t.integer :channel_id, :null => false
      t.decimal :video_elapsed, :default => 0.0, :null => false
      t.string :event_type, :default => :view, :null => false

      t.timestamps
    end
  end

  def self.down
    drop_table :events
  end
end
