module Aji
  class TwitterAPI
    def initialize token=nil, secret=nil, consumer_key=nil, consumer_secret=nil
      @token, @secret = token, secret
      consumer_key ||= Aji.conf['CONSUMER_KEY']
      consumer_secret ||= Aji.conf['CONSUMER_SECRET']
      @client = Twitter::Client.new :oauth_token => token,
        :oauth_token_secret => secret, :consumer_key => consumer_key,
        :consumer_secret => consumer_secret
    end

    def video_mentions_in_feed
      tweets_with_videos = filter_links @client.home_timeline(:count => 200,
       :include_entities => true)
      tweets_with_videos.map{|t| Parsers::Tweet.parse t }.reject do |mention|
        processor = MentionProcessor.new mention
        processor.perform
        processor.failed? || processor.no_videos?
      end
    end

    def valid_uid? uid
      @client.user? uid.to_i
    end

    def valid_username? username
      @client.user? username
    end

    def user_info uid
      @client.user uid.to_i
    end

    private
    def filter_links tweets
      tweets.reject do |tweet|
        tweet.fetch('entities', {}).fetch('urls', []).empty?
      end
    end

    def self.client
      @@singleton = TwitterAPI.new
    end
  end
end
