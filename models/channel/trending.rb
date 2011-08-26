require 'net/http'
require 'json'

module Aji
  class Channel::Trending < Channel
    include Redis::Objects

    sorted_set :recent_zset
    def recent_video_ids limit=-1
      (recent_zset.revrange 0, limit).map(&:to_i)
    end

    def push_recent video, relevance=Time.now.to_i
      recent_zset[video.id] = relevance
      n = 1 + Aji.conf['MAX_RECENT_VIDEO_IDS_IN_TRENDING']
      Aji.redis.zremrangebyrank recent_zset.key, 0, -n
    end

    def refresh_content force=false
      in_flight = []
      at_time_i = Time.now.to_i

      start = Time.now
      recent_video_ids_at_time = recent_video_ids
      recent_video_ids_at_time.each do |vid|
        video = Aji::Video.find_by_id vid
        next if video.nil? || video.blacklisted?
        in_flight << { :vid => vid, :relevance => video.relevance(at_time_i) }
      end
      Aji.log "Collected #{in_flight.count} recent videos in #{Time.now-start} s."

      start = Time.now
      in_flight.sort!{ |x,y| y[:relevance] <=> x[:relevance] }
      Aji.log "Sorted #{in_flight.count} videos in #{Time.now-start} s. Top 5: #{in_flight.first(5).inspect}"

      start = Time.now; populated_count = 0
      max_in_flight = Aji.conf['MAX_VIDEOS_IN_TRENDING']
      in_flight.first(max_in_flight).each do |h|
        video = Aji::Video.find_by_id h[:vid]
        next if video.nil?
        if !video.populated?
          video.populate
          populated_count += 1
        end
        push video, h[:relevance]
      end
      Aji.log "Replace #{[max_in_flight,in_flight.count].min} (#{populated_count} populated) content videos in #{Time.now-start} s."
      update_attribute :populated_at, Time.now
    end

    def thumbnail_uri
      "http://beta.#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def self.singleton
      Trending.first || Trending.create!(:title => "NowPopular")
    end
  end
end
