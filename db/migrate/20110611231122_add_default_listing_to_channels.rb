class AddDefaultListingToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :default_listing, :boolean, :default => false, :null => false
  end
  
  def self.down
    remove_column :channels, :default_listing
  end
end
