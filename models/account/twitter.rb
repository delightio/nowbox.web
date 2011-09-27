module Aji
  # ## Account::Twitter Schema Extensions
  # - recent_zset: Redis::Objects::SortedSet
  class Account::Twitter < Account
    include Redis::Objects
    include Mixins::RecentVideos
    include Aji::TankerDefaults::Account

    validates_presence_of :uid
    validates_uniqueness_of :uid

    has_many :mentions, :foreign_key => :author_id

    after_create :set_provider

    def profile_uri
      "http://twitter.com/#{username}"
    end

    def thumbnail_uri
      info['profile_image_url'] ||
        "http://api.twitter.com/1/users/profile_image/#{username}.json"
    end

    def realname
      info['name'] || ""
    end

    def description
      info['description'] || ""
    end

    def refresh_content force=false
      super force do |new_videos|
      end
    end

    def publish share
      api.publish format share.message, share.link
    end

    def format message, link
      coda = " #{link} via @nowbox for iPad"
      if (message + coda).length > 140
        message[0..message.length - (3 + coda.length)] << "..." << coda
      else
        message << coda
      end
    end

    def refresh_influencers
      # TODO: This method is very Java. We should find a Better Way (tm)
      # We get users from twitter 100 at a time, so we crawl over their API
      # until we get every full page, then pull the final page.
      resp_struct = ::Twitter.friends username
      while resp_struct.users.length == 100
        resp_struct.users.each do |user|
          influencer_set << Account::Twitter.find_or_create_by_uid(
            user.id.to_s, :info => user.to_hash,
            :username => user.screen_name).id
        end
        resp_struct = ::Twitter.friends username,
          :cursor => resp_struct.next_cursor
      end
      resp_struct.users.each do |user|
        influencer_set << Account::Twitter.find_or_create_by_uid(
          user.id.to_s, :info => user.to_hash,
          :username => user.screen_name).id
      end
    end

    def mark_spammer
      Aji.redis.sadd "spammers", id
      mentions.each { |m| m.mark_spam }
      blacklist
    end

    def authorized?
      credentials.has_key? 'token' and credentials.has_key? 'secret'
    end

    private
    # HACK: This is long, complex, blocking, and tightly coupled. A good
    # candidate for refactoring later.
    def harvest_tweets
      ::Twitter.user_timeline(username || uid, :include_entities => true,
                              :count => 200).each do |tweet|
        mention = Parsers['twitter'].parse tweet.to_hash do |tweet_hash|
          MentionProcessor.video_filters['twitter'].call tweet_hash
        end

        next if mention.nil?

        processor = MentionProcessor.new mention, self
        processor.perform

        if processor.failed?
          Aji.log "Processing failed due to #{processor.errors}"
        end
                              end


    rescue ::Twitter::BadGateway, ::Twitter::InternalServerError,
      ::Twitter::ServiceUnavailable => e
      Aji.log :WARN, "#{e.class}: #{e.message}"
    end

    def api
      @api ||= TwitterAPI.new credentials['token'], credentials['secret']
    end

    def set_provider
      update_attribute :provider, 'twitter'
    end

    def existing?
      api.valid_uid? uid
    end
  end
end

