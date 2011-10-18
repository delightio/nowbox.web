class SlapIndexesEveryDamnPlace < ActiveRecord::Migration
  def self.up
    add_index :accounts_channels, :account_id
    add_index :accounts_channels, :channel_id

    add_index :accounts, :stream_channel_id
  end

  def self.down
    remove_index :accounts_channels, :account_id
    remove_index :accounts_channels, :channel_id

    remove_index :accounts, :stream_channel_id
  end
end
