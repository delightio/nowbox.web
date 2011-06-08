class AddAuthorToVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :author_id, :integer, :null => false
  end

  def self.down
    remove_column :videos, :author_id
  end
end
