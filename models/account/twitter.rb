module Aji
  # ## Account::Twitter Schema Extensions
  # - recent_zset: Redis::Objects::SortedSet
  class Account::Twitter < Account
    include Redis::Objects
    sorted_set :recent_zset
    include Mixins::RecentVideos

    validates_presence_of :username
    validates_uniqueness_of :username

    has_many :mentions, :foreign_key => :author_id

    after_create :set_provider

    def profile_uri
      "http://twitter.com/#{username}"
    end

    def thumbnail_uri
      info['profile_image_url'] ||
      "http://api.twitter.com/1/users/profile_image/#{username}.json"
    end

    def description
      info['description'] || ""
    end

    def refresh_content force=false
      new_videos = []
      refresh_lock.lock do
        return [] if recently_populated? && content_video_ids.count > 0 &&
          !force
        harvest_tweets
        videos = recent_video_ids.map { |id| Aji::Video.find_by_id id }.
          select { |v| not (v.nil? || v.blacklisted?) }
        Aji.log "Found #{videos.count} videos in #{username}'s Twitter stream"
        videos.each do |video|
          mention = mentions.detect { |m| m.videos.include? video }
          video.populate unless video.populated?
          push(video, mention.published_at.to_i) and
            new_videos << video if video.populated?
        end
        update_attribute :populated_at, Time.now
      end
      new_videos
    end

    def publish share
      authorize_with_twitter! do
        Twitter.update format_for_twitter(share.message, share.link)
        share.published_to << :twitter
        share.save || puts("Could not save #{share.inspect}")
      end
    end

    def format_for_twitter message, link
      coda = " #{share.link} via @nowmov for iPad"
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
          influencer_set << Account::Twitter.find_or_create_by_username(
            user.screen_name.to_s, :info => user.to_hash, :uid => user.id).id
        end
        resp_struct = ::Twitter.friends username,
          :cursor => resp_struct.next_cursor
      end
      resp_struct.users.each do |user|
          influencer_set << Account::Twitter.find_or_create_by_username(
            user.screen_name.to_s, :info => user.to_hash, :uid => user.id).id
      end
    end

    def mark_spammer
      h = {}
      mentions.each do |m|
        h[:mid] = m.id
        h[:s] = m.spam?
        h[:vids] = m.videos.map &:id
      end
      Aji.log :INFO, "* spammer * Account::Twitter[#{id}].mentions: [#{h.inspect}]"
      return
      
      mentions.map do |m|
        m.mark_spam
        m.destroy
      end
      blacklist
    end

    def authorized?
      credentials.has_key? 'token' and credentials.has_key? 'secret'
    end

    # This method authorizes the global twitter account to act on behalf of this
    # user. If the optional block is given then after running the block the
    # client will be deauthorized. Otherwise this will modify the state of the
    # global twitter client.
    def authorize_with_twitter!
      fail "No credentials for #{username} (Account[#{id}])" unless authorized?
      ::Twitter.configure do |c|
        c.consumer_key = Aji.conf['CONSUMER_KEY']
        c.consumer_secret = Aji.conf['CONSUMER_SECRET']
        c.oauth_token = credentials['token']
        c.oauth_token_secret = credentials['secret']
      end
      if block_given?
        yield
        ::Twitter.configure do |c|
          c.oauth_token = nil
          c.oauth_token_secret = nil
        end
      end
    end

    private
    # HACK: This is long, complex, blocking, and tightly coupled. A good
    # candidate for refactoring later.
    def harvest_tweets
      ::Twitter.user_timeline(username || uid, :include_entities => true,
        :count => 200).each do |tweet|
        mention = Parsers['twitter'].parse tweet.to_hash do |tweet_hash|
          Mention::Processor.video_filters['twitter'].call tweet_hash
        end

        next if mention.nil?

        processor = Mention::Processor.new mention, self
        processor.perform

        if processor.failed?
          Aji.log "Processing failed due to #{processor.errors}"
        end
      end


    rescue ::Twitter::BadGateway, ::Twitter::InternalServerError,
      ::Twitter::ServiceUnavailable => e
      Aji.log :WARN, "#{e.class}: #{e.message}"
    end

    def set_provider
      update_attribute :provider, 'twitter'
    end
  end
end

