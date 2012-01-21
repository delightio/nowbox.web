require_relative '../aji'
include Aji

start = Time.now
n_days = 40

existing_channel_ids_key = 'existing_channel_ids'
subscribed_channel_ids_key = 'subscribed_channel_ids'

[ existing_channel_ids_key,
  subscribed_channel_ids_key ].each {|k| Aji.redis.del k }

channel_ids = Channel::Account.where(:created_at=>n_days.days.ago..Time.now).select(:id).map(&:id);
channel_ids.each do |id|
  Aji.redis.sadd existing_channel_ids_key, id
end;

User.where(:created_at=>n_days.days.ago..Time.now).select(:id).each do |user|
  user.subscribed_channel_ids.each do |id|
    Aji.redis.sadd subscribed_channel_ids_key, id
  end
end;

unsubscribed_channel_ids = Aji.redis.sdiff existing_channel_ids_key, subscribed_channel_ids_key;


puts "#{Aji.redis.scard existing_channel_ids_key} total channels created."
puts "#{User.count} users subscribed to #{Aji.redis.scard subscribed_channel_ids_key} channels."
puts "#{unsubscribed_channel_ids.count} (#{unsubscribed_channel_ids.count*100/(Aji.redis.scard existing_channel_ids_key)} percent of total) channels were not subscribed to."

# unsubscribed_channel_ids.sample(100).each do |id|
#   events = Event.where(:channel_id=>id)
#   next if events.count == 0
#   puts "Channel[#{id}] has #{events.count} events:"
#   events.first(10).each {|e| puts e };
# end;

puts
puts "  Done in #{Time.now-start} seconds."
