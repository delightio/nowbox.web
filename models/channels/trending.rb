require 'net/http'
require 'json'

module Aji
  module Channels
    class Trending < Channel

      def serializable_hash options={}
        h = super
        h["title"] = "Trending"
        h
      end

      def populate args={}
        url = args[:url] || "nowmov.com"
        path = args[:path] || "/live/videos"
        limit = args[:limit] || 100
        # Target is mobile since we'll always be going to the iPad
        params = "?target=mobile&limit=#{limit.to_i}"
        path = path + params
        response = Net::HTTP.get url, path
        video_hashes = JSON.parse response
        video_hashes.each_with_index do |video_hash, index|
          begin
            v = YouTubeIt::Client.new.video_by video_hash["service_external_id"]
            video = Video.find_or_create_from_youtubeit_video v
            content_zset[video.id] = limit - index
          rescue => e
            puts "Invalid video, #{video_hash['service_external_id']}: #{e}"
            Resque.enqueue Aji::Queues::ExamineVideo, video_hash["service_external_id"]
            next
          end
        end
      end
    end
  end
end
