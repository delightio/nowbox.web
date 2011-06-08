class AddKeywordsToChannel < ActiveRecord::Migration
  def self.up
    add_column :channels, :keywords, :string
  end

  def self.down
    remove_column :channels, :keywords
  end
end
