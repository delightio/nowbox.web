class DropCategoryFromChannels < ActiveRecord::Migration
  def self.up
    remove_column :channels, :category
  end

  def self.down
    add_column :channels, :category, :string
  end
end
