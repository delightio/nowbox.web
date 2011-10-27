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
        mentions.concat extract_video_mentions parse_mentions posts
        (pages - 1).times do
          tracker.hit!
          posts = posts.next_page

          break if posts.nil?
          mentions.concat extract_video_mentions parse_mentions posts
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

    def mention_ids_from_my_feed
      Aji.redis.lrange("debug:mention_ids_from_#{@token}", 0, -1).map(&:to_i)
    end

    private
    def parse_mentions posts
      posts.map do |post|
        Parsers::FBLink.parse(post).tap do |mention|
          Aji.redis.lpush "debug:mention_ids_from_#{@token}", mention.id
        end
      end
    end

    def parse_mentions_with_links posts
      posts.select { |p| p['link'] }.map{ |post| Parsers::FBLink.parse post }
    end


    def extract_video_mentions mentions
      mentions.reject do |mention|
        processor = MentionProcessor.new mention
        processor.perform
        processor.failed? || processor.no_videos?
      end
    end
  end
end
