require_relative '../aji'

include Aji

def print_stats api
  time_remaining = api.seconds_until_available.seconds
  time_since_start = (api.cooldown - time_remaining).seconds

  puts "API has made #{api.hit_count} of #{api.hits_per_session} in the last \
#{time_since_start.inspect} and has #{time_remaining.inspect} until resetting."
end

def print_aggregate_stats apis
  puts "There are #{apis.size} currently operating authorized Twitter apis"
  return if apis.empty?

  average_hits = apis.map(&:hit_count).inject(&:+) / apis.size.to_f
  puts "With an average hit rate of #{average_hits} over #{1.hour.inspect}"
end

@facebook_tracker = FacebookAPI.new("dummy token").tracker
@youtube_tracker = YoutubeAPI.new.tracker

@default_twitter_tracker = TwitterAPI.new(uid: "dummy id").tracker

@twitter_trackers = Aji.redis.keys("api_tracker:TwitterAPI:*").map do
  |tracker_key|
  default_twitter_tracker.dup.tap do |tracker|
    def tracker.key
      tracker_key
    end
  end
end

print_stats @facebook_tracker
print_stats @youtube_tracker

print_aggregate_stats @twitter_trackers

