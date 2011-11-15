module Aji
  class TwitterAPI
    FARADAY_OPTIONS = { :adapter => :typhoeus }

    def initialize consumer_key=nil, consumer_secret=nil, user_opts
      if user_opts.key? :token and user_opts.key? :secret
        @token, @secret = user_opts[:token], user_opts[:secret]
      elsif user_opts.key? :uid
        @uid = user_opts[:uid].to_i
      else
        raise ArgumentError, "Must supply :token and :secret, or :uid"
      end

      consumer_key ||= Aji.conf['CONSUMER_KEY']
      consumer_secret ||= Aji.conf['CONSUMER_SECRET']
      @client = Twitter::Client.new oauth_token: @token,
        oauth_token_secret: @secret, consumer_key: consumer_key,
        consumer_secret: consumer_secret,
        faraday_options: { :adapter => :typhoeus }
    end

    def video_mentions_in_feed
      [].tap do |mentions|
        2.times do |page|
          tracker.hit!
          link_tweets = filter_links @client.home_timeline(:count => 100,
            :include_entities => true, :page => page)
          link_tweets.map{|t| Parsers::Tweet.parse t }.reject do |mention|
            processor = MentionProcessor.new mention
            processor.perform
            processor.failed? || processor.no_videos?
          end.each do |video_mention|
            mentions << video_mention
          end
        end
      end
    end

    def video_mentions_i_post
      tracker.hit!
      link_tweets = filter_links @client.user_timeline(@uid,
        :count => 200, :include_entities => true)
      link_tweets.map{|t| Parsers::Tweet.parse t }.reject do |mention|
        processor = MentionProcessor.new mention
        processor.perform
        processor.failed? || processor.no_videos?
      end
    end

    def valid_uid? uid
      tracker.hit!
      @client.user? uid.to_i
    end

    def valid_username? username
      tracker.hit!
      @client.user? username
    end

    def user_info uid
      tracker.hit!
      @client.user uid.to_i
    end

    def tracker
      @tracker ||= APITracker.new "#{self.class}:#{@token}", Aji.redis,
        cooldown: 1.hour, hits_per_session: 350
    end

    def publish body_text
      tracker.hit!
      @client.update body_text
    end

    private
    def filter_links tweets
      tweets.reject do |tweet|
        tweet.fetch('entities', {}).fetch('urls', []).empty?
      end
    end

    def self.client
      @@singleton = TwitterAPI.new faraday_options: { :adapter => :typhoeus }
    end
  end
end
