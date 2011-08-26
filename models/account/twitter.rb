module Aji
  # ## Account::Twitter Schema Extensions
  # - recent_zset: Redis::Objects::SortedSet
  class Account::Twitter < Account
    after_create :set_provider

    validates_presence_of :username
    validates_uniqueness_of :username
    include Redis::Objects
    sorted_set :recent_zset
    USER_TIMELINE_URL = "http://api.twitter.com/1/statuses/user_timeline.json"
    serialize :info, Hash
    serialize :auth_info, Hash
    serialize :credentials, Hash

    def profile_uri; "http://twitter.com/#{username}"; end

    def thumbnail_uri
      (info['profile_image_url'] rescue nil) ||
      "http://api.twitter.com/1/users/profile_image/#{username}.json"
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

    def refresh_content force=false
      new_videos = []
      refresh_lock.lock do
        return [] if recently_populated? && content_video_ids.count > 0 && !force

        harvest_tweets

        videos = recent_video_ids.map { |id| Aji::Video.find_by_id id }.
          select { |v| not (v.nil? || v.blacklisted?) }
        Aji.log "Found #{videos.count} videos in #{username}'s Twitter stream"

        videos.each do |video|
          video.populate unless video.populated?
          push video and new_videos << video if video.populated?
        end

        update_attribute :populated_at, Time.now
      end
      new_videos
    end

    def push_recent video, relevance=Time.now.to_i
      recent_zset[video.id] = relevance
      n = 1 + Aji.conf['MAX_RECENT_VIDEO_IDS_IN_TRENDING']
      Aji.redis.zremrangebyrank recent_zset.key, 0, -n
    end

    def recent_video_ids limit=-1
      (recent_zset.revrange 0, limit).map(&:to_i)
    end

    # HACK: This is long, complex, blocking, and tightly coupled. A good
    # candidate for refactoring later.
    def harvest_tweets
      tweets = HTTParty.get(USER_TIMELINE_URL, :query => { :count => 200,
                            :screen_name => username, :include_entities => true },
                            :parser => Proc.new do |body|
                              begin
                                 MultiJson.decode body
                              rescue MultiJson::DecodeError => e
                                nil
                              end
                          end)
      tweets.compact.each do |tweet|

        mention = Parsers['twitter'].parse tweet do |tweet_hash|
          Mention::Processor.video_filters['twitter'].call tweet_hash
        end
        next if mention.nil?

        processor = Mention::Processor.new mention, self
        processor.perform

        if processor.failed?
          Aji.log "Processing failed due to #{processor.errors}"
        end
      end
    end

    def set_provider
      update_attribute :provider, 'twitter'
    end
    private :set_provider

  end
end
