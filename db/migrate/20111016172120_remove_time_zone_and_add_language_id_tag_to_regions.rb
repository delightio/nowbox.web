class RemoveTimeZoneAndAddLanguageIdTagToRegions < ActiveRecord::Migration
  def self.up
    puts "removing time_zone column in regions"
    remove_column :regions, :time_zone
    puts "adding language column in regions"
    add_column :regions, :language, :string
  end

  def self.down
    add_column :regions, :time_zone, :string
    remove_column :regions, :language
  end
end
