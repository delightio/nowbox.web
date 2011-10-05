class AddIndexToRegions < ActiveRecord::Migration
  def self.up
    add_index :regions, :locale
    add_index :regions, :time_zone
  end

  def self.down
    remove_index :regions, :locale
    remove_index :regions, :time_zone
  end
end
