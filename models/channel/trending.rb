require 'net/http'
require 'json'

module Aji
  class Channel::Trending < Channel
    include Redis::Objects
    include Mixins::RecentVideos

    # I have so much hate for this method but won't fix it now since it isn't a
    # "priority"
    def refresh_content force=false
      super force do |new_videos|
        in_flight = []
        at_time_i = Time.now.to_i

        start = Time.now
        recent_video_ids_at_time = recent_video_ids
        Aji.log "Processing #{recent_video_ids_at_time.count} in-flight videos..."
        recent_video_ids_at_time.each do |vid|
          video = Aji::Video.find_by_id vid
          next if video.nil? || video.blacklisted?
          in_flight << { :video => video, :relevance => video.relevance(at_time_i) }
        end
        Aji.log "Collected #{in_flight.count} recent videos in #{Time.now-start} s."

        start = Time.now
        in_flight.sort!{ |x,y| y[:relevance] <=> x[:relevance] }
        Aji.log "Sorted #{in_flight.count} videos in #{Time.now-start} s. " +
          "Top 5: #{in_flight.first(5).inspect}"

        start = Time.now; populated_count = 0
        max_in_flight = Aji.conf['MAX_VIDEOS_IN_TRENDING']
        in_flight = in_flight.first(max_in_flight*3/2)
        in_flight.each do |h|
          video = h[:video]
          video.populate unless video.populated?

          if video.populated?
            populated_count += 1
            new_videos << video
            push video, h[:relevance]
          end
        end

        # Before we truncate, we will make sure the video within
        # content_videos are the one we have in_flight
        (content_video_ids - in_flight.map{|h| h[:video].id}).each { |vid| pop_by_id vid }
        truncate max_in_flight

        # Create channels from authors of top videos for search
        create_channels_from_top_authors content_videos(50)

        Aji.log "Replace #{[max_in_flight,in_flight.count].min} (#{populated_count} populated) content videos in #{Time.now-start} s."
        update_attribute :populated_at, Time.now
      end
    end

    def create_channels_from_top_authors top_videos
      top_videos.each do | video |
        Resque.enqueue(
          Queues::RefreshChannel, video.author.to_channel.id)
      end
    end

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def self.singleton
      Trending.first || Trending.create!(:title => "NowPopular")
    end
  end
end
