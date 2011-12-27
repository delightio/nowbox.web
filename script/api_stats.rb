require_relative '../aji'

include Aji

class APITracker
  def print_recent_throttles n=10
    throttles = redis.zrevrange throttle_count_key, 0, n, :with_scores=>true
    throttles.each_slice(2) do |h, t|
      puts "#{Time.now.to_i-t.to_i} s ago: #{h}"
    end
  end

  def print_stats
    time_remaining = seconds_until_available.seconds
    time_since_start = (cooldown - time_remaining).seconds

    puts "#{namespace} (availabe? #{available?}, throttle_set? #{throttle_set?}) " +
         "has made #{hit_count} of #{hits_per_session} in the last #{time_since_start.inspect} " +
         "and has #{time_remaining.inspect} until resetting."
    print_recent_throttles
    puts
  end
end

def print_aggregate_stats apis
  puts "There are #{apis.size} currently operating authorized Twitter apis"
  return if apis.empty?

  average_hits = apis.map(&:hit_count).inject(&:+) / apis.size.to_f
  puts "With an average hit rate of #{average_hits} over #{1.hour.inspect}"
end

def print_dropped_api_calls n=10
  dropped = Aji.redis.zrevrange "youtube_api:dropped_gets", 0, n, :with_scores=>true
  puts "#{dropped.count} recent dropped API calls:"
  dropped.each_slice(2) do |h, t|
    puts "#{Time.now.to_i-t.to_i} s ago: #{h}"
  end
  puts
end

@facebook_tracker = FacebookAPI.new("dummy token").tracker
@youtube_gt = YoutubeAPI.global_tracker
@youtube_at = YoutubeAPI.authed_tracker
@youtube_at_post = YoutubeAPI.authed_post_tracker

@default_twitter_tracker = TwitterAPI.new(uid: "dummy id").tracker

@twitter_trackers =
  Aji.redis.keys("api_tracker:aji::twitterapi:*").map do |tracker_key|
  @default_twitter_tracker.dup.tap do |tracker|
    tracker.instance_eval do
      def key
        @key
      end

      def key= new_key
        @key = new_key
      end
    end

    tracker.key = tracker_key
  end
end

@facebook_tracker.print_stats
@youtube_gt.print_stats
@youtube_at.print_stats
@youtube_at_post.print_stats

print_dropped_api_calls

print_aggregate_stats @twitter_trackers

# Welcome to the interactive stats console. You have access to all the functions
# and ivars of script/api_stats.rb
binding.pry if ARGV.first == '-i'

