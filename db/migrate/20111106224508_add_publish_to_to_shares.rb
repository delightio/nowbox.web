class AddPublishToToShares < ActiveRecord::Migration
  def self.up
    add_column :shares, :publish_to, :string
  end

  def self.down
    remove_column :shares, :publish_to
  end
end
