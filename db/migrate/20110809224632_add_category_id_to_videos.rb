class AddCategoryIdToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :category_id, :integer
  end

  def self.down
    remove_column :videos, :category_id
  end
end
