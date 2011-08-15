class ChangeEventTypeToActionAndRemoveNoNullOnVideoIdOnEvents < ActiveRecord::Migration
  def self.up
    rename_column :events, :event_type, :action
    change_column :events, :video_id, :integer, :null => true
  end

  def self.down
    rename_column :events, :action, :event_type
    change_column :events, :video_id, :integer, :null => false
  end
end
