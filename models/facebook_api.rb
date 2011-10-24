module Aji
  class FacebookAPI
    def initialize auth_token
      @token = auth_token
      @koala = Koala::Facebook::API.new @token
    end

    def video_mentions_in_feed pages=5
      [].tap do |mentions|
        tracker.hit!
        posts = @koala.get_connections "me", "home"
        mentions.concat extract_video_mentions filter_links posts
        (pages - 1).times do
          tracker.hit!
          posts = posts.next_page

          break if posts.nil?
          mentions.concat extract_video_mentions filter_links posts
        end
      end
    end

    def publish body_text
      tracker.hit!
      @koala.put_wall_post body_text
    end

    def tracker
      @@tracker ||= APITracker.new self.class.to_s, Aji.redis, cooldown: 1.hour,
        hits_per_session: 1000
    end

    private
    def filter_links posts
      posts.select { |p| p['link'] }
    end

    def extract_video_mentions links
      links.map { |link| Parsers['facebook'].parse link }.reject do |mention|
        processor = MentionProcessor.new mention
        processor.perform
        processor.failed? || processor.no_videos?
      end
    end
  end
end
