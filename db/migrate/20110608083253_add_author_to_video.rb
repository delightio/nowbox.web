class AddExternalAccountToVideo < ActiveRecord::Migration
  def self.up
    add_column :videos, :external_account_id, :integer, :null => false
  end

  def self.down
    remove_column :videos, :author_id
  end
end
