module Aji
  module Channels
    class TwitterAccount < Channel
      include Redis::Objects

      belongs_to :account, :class_name => 'Aji::Account::Twitter'
      before_create :set_default_title
      sorted_set :recent_zset

      USER_TIMELINE_URL = "http://api.twitter.com/1/statuses/user_timeline.json"

      def refresh_content force=false
        refresh_lock.lock do
        return if recently_populated? && content_video_ids.count > 0 && !force

          harvest_tweets

          in_flight = []
          at_time_i = Time.now.to_i

          start = Time.now
          recent_video_ids_at_time = recent_video_ids
          recent_video_ids_at_time.each do |vid|
            video = Aji::Video.find_by_id vid
            next if video.nil? || video.blacklisted?
            in_flight << { :vid => vid, :relevance => video.relevance(at_time_i) }
          end
          Aji.log "Collected #{in_flight.count} recent videos in #{Time.now-start} s."

          start = Time.now
          in_flight.sort!{ |x,y| y[:relevance] <=> x[:relevance] }
          Aji.log "Sorted #{in_flight.count} videos in #{Time.now-start} s. Top 5: #{in_flight.first(5).inspect}"
          start = Time.now; populated_count = 0
          max_in_flight = Aji.conf['MAX_VIDEOS_IN_TRENDING']
          in_flight.first(max_in_flight).each do |h|
            video = Aji::Video.find_by_id h[:vid]
            next if video.nil?
            if !video.populated?
              video.populate
              populated_count += 1
            end
            push video, h[:relevance]
          end
          Aji.log "Replace #{[max_in_flight,in_flight.count].min} (#{populated_count} populated) content videos in #{Time.now-start} s."
          update_attribute :populated_at, Time.now
        end
      end

      # HACK: This is long, complex, blocking, and tightly coupled. A good
      # candidate for refactoring later.
      def harvest_tweets
        tweets = HTTParty.get(USER_TIMELINE_URL, :query => { :count => 200,
          :screen_name => account.username, :include_entities => true },
          :parser => Proc.new { |body| MultiJson.decode body })
        tweets.each do |tweet|
          Queues::Mention::Process.perform 'twitter', tweet, self.id
        end
      end

      def thumbnail_uri
        account.thumbnail_uri
      end

      def recent_video_ids limit=-1
        (recent_zset.revrange 0, limit).map(&:to_i)
      end

      def push_recent video, relevance=Time.now.to_i
        recent_zset[video.id] = relevance
        n = 1 + Aji.conf['MAX_RECENT_VIDEO_IDS_IN_TRENDING']
        Aji.redis.zremrangebyrank recent_zset.key, 0, -n
      end

      # Class methods below
      def self.find_or_create_by_account account, args={}
        # TODO: I find this questionable.
        populate_if_new = args.delete :populate_if_new
        args.merge! :account => account
        account.channel ||= Channels::TwitterAccount.create args
        account.channel.refresh_content if populate_if_new
        account.channel
      end

      def self.find_or_create_by_username username, args={}
        account = Account::Twitter.find_or_create_by_username username
        self.find_or_create_by_account account args
      end

      def self.searchable_columns; [:title]; end

      # Private instance methods below.
      private
      def set_default_title
        self.title ||= "@#{account.username}'s Tweeted Videos"
      end
    end
  end
end
