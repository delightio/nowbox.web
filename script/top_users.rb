include Aji

class ::Array
  def odd_values
    self.values_at(* self.each_index.select {|i| i.odd?})
  end
  def even_values
    self.values_at(* self.each_index.select {|i| i.even?})
  end
end

first_arg = ARGV.first
n = if first_arg.to_i.to_s == first_arg
      first_arg.to_i
    else
      100
    end

k = 'user_ids_by_seconds';
user_ids_with_sec = redis.zrevrange(k, 0, n, :with_scores=>true);
user_ids = user_ids_with_sec.even_values;
time_on_app = user_ids_with_sec.odd_values.map { |s| s.to_i/60 };

puts "Top #{n} users:"
user_ids.each_with_index do |uid, index|
  user = User.find uid
  puts "#{index.to_s.rjust(4)}. User[#{uid.rjust(6)}], #{user.subscribed_channel_ids.count.to_s.rjust(3)} channels, #{time_on_app[index].to_s.rjust(5)} minutes, #{user.events.count.to_s.rjust(4)} events. Last event: #{user.events.latest(1).first.created_at.age}"
end;

# # channel count vs minutes
# user_ids.each_with_index do |uid, index|
#   user = User.find uid
#   puts "#{user.subscribed_channel_ids.count}\t#{time_on_app[index]}"
# end;

# # user id vs minutes
# user_ids.each_with_index do |uid, index|
#   puts "#{uid}\t#{time_on_app[index]}"
# end;

# # number of video watched vs total minutes
# user_ids.each_with_index do |uid, index|
#   user = User.find uid
#   puts "#{user.history_channel.content_video_ids.count}\t#{time_on_app[index]}"
# end;
