module Aji
  class TwitterAPI
    def initialize token=nil, secret=nil
      @token, @secret = token, secret
      @client = Twitter::Client.new :oauth_token => token,
        :oauth_token_secret => secret, :include_entities => true,
        :consumer_key => Aji.conf['CONSUMER_KEY'],
        :consumer_secret => Aji.conf['CONSUMER_SECRET']
    end

    def videos_in_timeline
      @client.user_timeline
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

    def self.client
      @@singleton = TwitterAPI.new
    end
  end
end
