require 'net/http'
require 'json'

module Aji
  class Channel::Trending < Channel
    include Redis::Objects
    include Mixins::RecentVideos

    def refresh_content force=false
      super force do |new_videos|
        adjust_relevance_in_all_recent_videos -100, true

        # Populate the top N trending videos and add them to content_videos
        recent_videos(Aji.conf['MAX_VIDEOS_IN_TRENDING']).each do |v|
          next if v.blacklisted?
          v.populate do |populated|
            push populated, recent_relevance_of(populated)
          end
        end

        # Create channels from the top 50 authors
        top_authors = content_videos(50).map &:author
        create_channels_from_top_authors top_authors
        update_attribute :populated_at, Time.now
      end
    end

    def promote_video video, trigger
      adjust_relevance_of_recent_video video, trigger.significance
    end

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def description
      "What popular videos the world is watching right now!"
    end

    def self.singleton
      Trending.first || Trending.create!(:title => "NowPopular")
    end

    private

    def create_channels_from_top_authors top_authors
      top_authors.each do | author |
        channel = author.to_channel
        channel.background_refresh_content
        Aji.log "Trending: created Channel[#{channel.id}] for #{author.username}"
      end
    end


  end
end
