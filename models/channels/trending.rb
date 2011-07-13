require 'net/http'
require 'json'

module Aji
  module Channels
    class Trending < Channel

      sorted_set :recent_zset
      def recent_video_ids limit=-1
        (recent_zset.revrange 0, limit).map(&:to_i)
      end
      def push_recent video, relevance=Time.now.to_i
        recent_zset[video.id] = relevance
        Aji.redis.zremrangebyrank recent_zset.key, 0, -10001 # keep the latest 10000
      end

      def populate args={}
        in_flight = []
        at_time_i = Time.now.to_i
        
        start = Time.now
        recent_video_ids_at_time = recent_video_ids
        recent_video_ids_at_time.each do |vid|
          video = Aji::Video.find_by_id vid
          next if video.nil?
          in_flight << { :vid => vid, :relevance => video.relevance at_time_i}
        end
        Aji.log "Collected #{in_flight.count} recent videos in #{Time.now-start} s."
        
        start = Time.now
        in_flight.sort!{ |x,y| y[:relevance] <=> x[:relevance] }
        Aji.log "Sorted #{in_flight.count} videos in #{Time.now-start} s."
        
        start = Time.now; populated_count = 0
        max_in_flight = 2000
        in_flight.first(max_in_flight).each do |h|
          video = Aji::Video.find_by_id h[:vid]
          next if video.nil?
          if !video.is_populated?
            video.populate
            populated_count += 1
          end
          push video, h[:relevance]
        end
        Aji.log "Replace #{min(max_in_flight,in_flight.count)} (#{populated_count} populated) content videos in #{Time.now-start} s."
      end

      def serializable_hash options={}
        h = super
        h["title"] = "Trending"
        h
      end

    end
  end
end
