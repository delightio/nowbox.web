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
          influencer_set << Account::Twitter.find_or_create_by_uid(user.id.to_s,
            :info => user.to_hash, :username => user.screen_name).id
        end
        resp_struct = ::Twitter.friends username,
          :cursor => resp_struct.next_cursor
      end
      resp_struct.users.each do |user|
        influencer_set << Account::Twitter.find_or_create_by_uid(user.id.to_s,
          :info => user.to_hash, :username => user.screen_name).id
      end
    end

    def refresh_content force=false
      new_videos = []
      refresh_lock.lock do
        return [] if recently_populated? && content_video_ids.count > 0 && !force

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
          new_videos << video
        end
        Aji.log "Replace #{[max_in_flight,in_flight.count].min} (#{populated_count} populated) content videos in #{Time.now-start} s."
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
                            :parser => Proc.new { |body| MultiJson.decode body })
      tweets.each do |tweet|
        Queues::Mention::Process.perform 'twitter', tweet, self
      end
    end

    def set_provider
      update_attribute :provider, 'twitter'
    end
    private :set_provider

  end
end
