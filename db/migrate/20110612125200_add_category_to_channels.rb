class AddCategoryToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :category, :string, :default=>:undefined
  end

  def self.down
    remove_column :channels, :category
  end
end