module Aji
  class FacebookAPI
    def initialize auth_token
      @token = auth_token
      @koala = Koala::Facebook::API.new @token
    end

    def video_mentions_in_feed
      posts = @koala.get_connections "me", "home"
      links = posts.select { |p| p['type'] == 'link' }
      links.map { |link| Parsers['facebook'].parse link }.reject do |mention|
        processor = Mention::Processor.new mention
        processor.perform
        processor.failed? || processor.no_videos?
      end
    end
  end
end
