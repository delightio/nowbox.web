class RenameExternalAccountIdToAuthorIdOnVideos < ActiveRecord::Migration
  def self.up
    rename_column :videos, :external_account_id, :author_id
  end

  def self.down
    rename_column :videos, :author_id, :external_account_id
  end
end
