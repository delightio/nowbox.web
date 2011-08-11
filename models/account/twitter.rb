module Aji
  # ## Account::Twitter Schema Extensions
  # - tweeted_zset: Redis::Objects::SortedSet
  class Account::Twitter < Account
    has_one :channel, :class_name => 'Aji::Channels::TwitterAccount',
      :foreign_key => :account_id
    serialize :user_info, Hash

    def profile_uri; "http://twitter.com/#{username}"; end

    # TODO: LH 205
    def thumbnail_uri
      "http://api.twitter.com/1/users/profile_image/#{uid}.json"
    end

    def publish share
      ::Twitter.configure do |c|
        c.consumer_key = Aji.conf['CONSUMER_KEY']
        c.consumer_secret = Aji.conf['CONSUMER_SECRET']
        c.oauth_token = credentials['oauth_token']
        c.oauth_token_secret = credentials['oauth_verifier']
      end
      Twitter.update format_for_twitter(share.message, share.link)
      share.published_to << :twitter
      share.save || puts("Could not save #{share.inspect}")
    end

    def format_for_twitter message, link
      coda = " #{share.link} via @nowmov for iPad"
      if (message + coda).length > 140
        message[0..message.length - (3 + coda.length)] << "..." << coda
      else
        message << coda
      end
    end
  end
end
