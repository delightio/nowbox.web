module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::CanRefreshContent

    validates_presence_of :uid
    validates_uniqueness_of :uid

    # Use an alias to allow Facebook accounts to implement the same protocal as
    # Channel::Trending without the need for a recent_zset buffer.
    alias_method :push_recent, :push

    def refresh_content force=false
      super force do |new_videos|
        links = api.get_connections "me", "links"
        # TODO: smelly
        new_videos.concat videos_from_graph_collection links
        new_videos.concat videos_from_graph_collection links.next_page
        new_videos.each { |v| v.populate }
        Aji.log "Found #{new_videos.count} in facebook links."
      end
    end

    def videos_from_graph_collection links
      videos = [].tap do |videos|
        links.each do |link|
          mention = Parsers[:facebook].parse link
          processor = Mention::Processor.new mention, self
          processor.perform
          videos.concat processor.found_videos
        end
      end
    end

    def description
      info['bio']
    end

    def thumbnail_uri
      "http://graph.facebook.com/#{uid}/picture"
    end

    def profile_uri
      info['link']
    end

    def authorized?
      credentials.key? 'token'
    end

    private
    def api
      @api ||= Koala::Facebook::API.new credentials['token']
    end

  end
end
