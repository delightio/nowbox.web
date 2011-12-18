launch_date = Time.new 2011, 12, 15
giveaway_dates = []
5.times { |n| giveaway_dates << launch_date + n * 1.days }

giveaway_dates.each do |start_time|
  end_time = start_time + 24.hours - 1.minute
  puts "Picking winner from #{start_time} to #{end_time}"

  shares = Share.where :created_at => start_time..end_time
  winning_shares = shares.sample 5
  unless winning_shares.empty?
    winning_shares.each do |winning_share|
      winner = winning_share.publisher
      puts "  Share[#{winning_share.id}], #{winner.realname} on http://#{winning_share.network}.com/#{winner.username}, uid: #{winner.uid}"
    end
  end
end