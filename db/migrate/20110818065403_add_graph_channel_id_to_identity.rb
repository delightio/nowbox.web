class AddGraphChannelIdToIdentity < ActiveRecord::Migration
  def self.up
    add_column :identities, :graph_channel_id, :integer
  end

  def self.down
    remove_column :identities, :graph_channel_id
  end
end
