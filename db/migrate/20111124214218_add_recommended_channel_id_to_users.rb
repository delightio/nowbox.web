class AddRecommendedChannelIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :recommended_channel_id, :integer
    puts "Creating recommended channel for #{Aji::User.count} users..."
    Aji::User.find_each do |u|
      if u.recommended_channel.nil?
        recommended = Aji::Channel::Recommended.create
        u.update_attribute :recommended_channel_id, recommended.id
      end
    end
    puts "Applying non null constriant..."
    change_column :users, :recommended_channel_id, :integer, :null => false
  end

  def self.down
    remove_column :users, :recommended_channel_id
  end
end
