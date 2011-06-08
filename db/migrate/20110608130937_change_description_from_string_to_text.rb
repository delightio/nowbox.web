class ChangeDescriptionFromStringToText < ActiveRecord::Migration
  def self.up
    remove_column :videos, :description
    add_column :videos, :description, :text
  end

  def self.down
    remove_column :videos, :description
    add_column :videos, :description, :string
  end
end
