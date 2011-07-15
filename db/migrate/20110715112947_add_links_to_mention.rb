class AddLinksToMention < ActiveRecord::Migration
  def self.up
    add_column :mentions, :links, :text
  end

  def self.down
    remove_column :mentions, :links
  end
end
