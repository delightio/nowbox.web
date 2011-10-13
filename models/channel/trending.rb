require 'net/http'
require 'json'

module Aji
  class Channel::Trending < Channel
    include Redis::Objects
    include Mixins::RecentVideos

    # Always allow trending channel to refresh
    def refresh_content force=true
      super force do |new_videos|
        start = Time.now
        # We want 1 mention to have effect over 4 hours.
        # 10,000 is default for 1 mention and we refresh 4 times an hour.
        increment_relevance_in_all_recent_videos -625
        Aji.log "Adjusted #{recent_video_id_count} recent videos in #{Time.now-start} s."

        start = Time.now
        # Populate the top N trending videos and add them to content_videos
        recent_videos(Aji.conf['MAX_VIDEOS_IN_TRENDING']).each do |v|
          next if v.blacklisted?
          v.populate do |populated|
            push populated, recent_relevance_of(populated)
          end
        end
        Aji.log "Pushed and populated #{Aji.conf['MAX_VIDEOS_IN_TRENDING']} videos in #{Time.now-start} s. " +
          "Top 5: "+ content_videos(5).map{|v| "#{v.external_id} (#{relevance_of(v)})"}.join(', ')

        # Create channels from the top 10 authors
        top_authors = content_videos(10).map &:author
        create_channels_from_top_authors top_authors

        update_attribute :populated_at, Time.now
      end
    end

    def promote_video video, trigger
      increment_relevance_of_recent_video video, trigger.significance
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
      debug = []
      top_authors.each do | author |
        channel = author.to_channel
        channel.background_refresh_content
        debug << "#{author.username} (cid: #{channel.id})"
      end
      Aji.log "Trending: channels created: #{debug.join(', ')}"
    end


  end
end
