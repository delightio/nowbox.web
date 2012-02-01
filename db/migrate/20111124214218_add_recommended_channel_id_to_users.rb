class AddRecommendedChannelIdToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :recommended_channel_id, :integer
    puts "Creating recommended channel for #{Aji::User.count} users..."
    count = 0
    Aji::User.find_each(:conditions => "recommended_channel_id IS NULL") do |u|
      if u.recommended_channel.nil?
        recommended = Aji::Channel::Recommended.create
        u.update_attribute :recommended_channel_id, recommended.id
        count += 1
        puts "#{count} users updated" if count % 1000 == 0
      end
    end
    puts "Final: #{count} users updated "
    puts "Applying non null constriant..."
    change_column :users, :recommended_channel_id, :integer, :null => false
  end

  def self.down
    remove_column :users, :recommended_channel_id
  end
end
