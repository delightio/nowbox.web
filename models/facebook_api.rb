module Aji
  class FacebookAPI
    def initialize auth_token
      @token = auth_token
      @koala = Koala::Facebook::API.new @token
    end

    def video_mentions_i_post pages=2
      [].tap do |mentions|
        posts = @koala.get_connections "me", "links"
        mentions.concat extract_video_mentions filter_links posts
        (pages - 1).times do
          posts = posts.next_page
          mentions.concat extract_video_mentions filter_links posts
        end
      end
    end

    def video_mentions_in_feed pages=5
      [].tap do |mentions|
        posts = @koala.get_connections "me", "home"
        mentions.concat extract_video_mentions filter_links posts
        (pages - 1).times do
          posts = posts.next_page
          mentions.concat extract_video_mentions filter_links posts
        end
      end
    end

    private
    def filter_links posts
      posts.select { |p| p['type'] == 'video' and p['link'] }
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
