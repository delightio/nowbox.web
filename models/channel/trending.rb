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

    def sorted_recent_videos at_time_i = Time.now.to_i
      start = Time.now
      in_flight = []
      recent_video_ids_at_time = recent_video_ids
      Aji.log "Processing #{recent_video_ids_at_time.count} in-flight videos..."
      recent_video_ids_at_time.each do |video_id|
        video = Video.find video_id
        next if video.blacklisted?
        in_flight << { :video_id => video_id,
                       :relevance => video.relevance(at_time_i) }
        Aji.log "  Processed #{in_flight.count} videos in #{Time.now-start} s." if in_flight.count % 100 == 0
      end
      Aji.log "Collected #{in_flight.count} recent videos in #{Time.now-start} s."

      start = Time.now
      sorted = in_flight.sort{ |x,y| y[:relevance] <=> x[:relevance] }
      Aji.log "Sorted #{in_flight.count} videos in #{Time.now-start} s. " +
        "Top 5: #{sorted.first(5).map{|h| [
        :video_id => h[:video_id],
        :relevance => h[:relevance] ]}}"
      sorted
    end

    def update_and_populate_content_videos in_flight, max_videos_in_trending
      start = Time.now

      new_videos = []
      populated_count = 0
      in_flight.each do |h|
        video = Video.find h[:video_id]
        video.populate
        if video.populated?
          populated_count += 1
          new_videos << video
          push video, h[:relevance]
        end
      end

      # Before we truncate to the requested size, we will
      # remove all outdated video ids.
      outdated_video_ids = content_video_ids - in_flight.map{ |h| h[:video_id] }
      outdated_video_ids.each { |vid| pop_by_id vid }
      truncate max_videos_in_trending

      Aji.log "Replace #{[max_videos_in_trending,in_flight.count].min} " +
        "(#{populated_count} populated) content videos in #{Time.now-start} s."

      new_videos
    end

    def create_channels_from_top_authors top_authors
      top_authors.each do | author |
        channel = author.to_channel
        channel.background_refresh_content
        Aji.log "Trending: created Channel[#{channel.id}] for #{author.username}"
      end
    end


  end
end
