class AddEventToShares < ActiveRecord::Migration
  def self.up
    add_column :shares, :event_id, :integer
  end

  def self.down
    remove_column :shares, :event_id
  end
end
