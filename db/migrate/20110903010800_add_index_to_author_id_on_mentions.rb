class AddIndexToAuthorIdOnMentions < ActiveRecord::Migration
  def self.up
    add_index :mentions, :author_id
  end

  def self.down
    remove_index :mentions, :author_id
  end
end
