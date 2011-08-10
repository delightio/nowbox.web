class AddRawTitleToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :raw_title, :string
    add_index :categories, :raw_title
  end

  def self.down
    remove_column :categories, :raw_title
  end
end
