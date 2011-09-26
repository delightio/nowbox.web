require 'net/http'
require 'json'

module Aji
  class Channel::Trending < Channel
    include Redis::Objects
    include Mixins::RecentVideos

    def refresh_content force=false
      super force do |new_videos|
        in_flight = sorted_recent_videos Time.now.to_i
        unless in_flight.empty?
          max_videos_in_trending = Aji.conf['MAX_VIDEOS_IN_TRENDING']
          new_videos = update_and_populate_content_videos(
            in_flight.first(max_videos_in_trending*3/2),
            max_videos_in_trending)
          create_channels_from_top_authors content_videos(50)

          update_attribute :populated_at, Time.now
        end
      end
    end

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def self.singleton
      Trending.first || Trending.create!(:title => "NowPopular")
    end

    private

    def sorted_recent_videos at_time_i = Time.now.to_i
      start = Time.now
      in_flight = []
      recent_videos_at_time = recent_videos
      Aji.log "Processing #{recent_videos_at_time.count} in-flight videos..."
      recent_videos_at_time.each do |video|
        next if video.blacklisted?
        in_flight << { :video => video, :relevance => video.relevance(at_time_i) }
        if in_flight.count <= 10 || in_flight.count % 50 == 0
          Aji.log "#{in_flight.count} inserted: Video[#{in_flight.last[:video].id}] w/ relevance of #{in_flight.last[:relevance]}"
        end
      end
      Aji.log "Collected #{in_flight.count} recent videos in #{Time.now-start} s."

      start = Time.now
      sorted = in_flight.sort{ |x,y| y[:relevance] <=> x[:relevance] }
      Aji.log "Sorted #{in_flight.count} videos in #{Time.now-start} s. " +
        "Top 5: #{sorted.first(5).inspect}"
      sorted
    end

    def update_and_populate_content_videos in_flight, max_videos_in_trending
      start = Time.now

      new_videos = []
      populated_count = 0
      in_flight.each do |h|
        video = h[:video]
        video.populate
        if video.populated?
          populated_count += 1
          new_videos << video
          push video, h[:relevance]
        end
      end

      # Before we truncate to the requested size, we will
      # remove all outdated video ids.
      outdated_video_ids = content_video_ids - in_flight.map{|h| h[:video].id}
      outdated_video_ids.each {|vid| pop_by_id vid }
      truncate max_videos_in_trending

      Aji.log "Replace #{[max_videos_in_trending,in_flight.count].min} " +
        "(#{populated_count} populated) content videos in #{Time.now-start} s."

      new_videos
    end

    def create_channels_from_top_authors top_videos
      top_videos.each do | video |
        Resque.enqueue(
          Queues::RefreshChannel, video.author.to_channel.id)
      end
    end


  end
end
