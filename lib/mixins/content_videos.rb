module Aji
  module Mixins
    module ContentVideos
      
      # We need to add the following BEFORE including this mixins because
      # Redis::Objects expect a database ID to generate a unique redis key
      #
      # ************************
      # include Redis::Objects
      # sorted_set :content_zset
      # ************************
      
      # TODO: This isn't a particularly robust interface. I'm writing my own Redis
      # object library so when that's finished we'll use it.
      def content_video_ids limit=-1
        (content_zset.revrange 0, limit).map(&:to_i)
      end
      
      def content_videos limit=-1
        content_video_ids(limit).map { |vid| Video.find vid }
      end
      
      def relevance_of video
        content_zset.score video.id
      end
      
      # Push a video into the channel's content.
      def push video, relevance=Time.now.to_i
        content_zset[video.id] = relevance
      end
      
    end
  end
end