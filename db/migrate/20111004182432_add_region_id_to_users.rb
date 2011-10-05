class AddRegionIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :region_id, :integer

    region = Aji::Region.undefined
    Aji.log "Assigning an undefined region, Region[#{region.id}], for existing users (count: #{Aji::User.count})..."
    Aji::User.find_each do |user|
      next unless user.region.nil?
      user.update_attribute :region_id, region.id
    end
  end

  def self.down
    remove_column :users, region_id
  end
end
