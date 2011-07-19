class AddPopulatedAtToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :populated_at, :datetime
  end

  def self.down
    remove_column :channels, :populated_at
  end
end
