class AddAccountIdToTwitterChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :account_id, :integer
  end

  def self.down
    remove_column remove_columnchannels, :account_id
  end
end
