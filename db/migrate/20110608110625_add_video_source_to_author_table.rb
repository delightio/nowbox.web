class AddVideoSourceToAuthorTable < ActiveRecord::Migration
  def self.up
    add_column :authors, :video_source, :string, :null => false
  end

  def self.down
    remove_column :authors, :video_source
  end
end
