class DropNotNullOnExternalAccountIdOnVideos < ActiveRecord::Migration
  def self.up
    change_column :videos, :external_account_id, :integer, :null => true
  end

  def self.down
    change_column :videos, :external_account_id, :integer, :null => false
  end
end
