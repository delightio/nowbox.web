module Aji
  module Mixins
    module RecentVideos
      # We need to add the following BEFORE including this mixins because
      # Redis::Objects expect a database ID to generate a unique redis key
      #
      # ************************
      # include Redis::Objects
      # ************************
      def self.included(klass)
        klass.sorted_set :recent_zset
      end

      def recent_video_ids limit=-1
        (recent_zset.revrange 0, limit).map(&:to_i)
      end

      def push_recent video, relevance=Time.now.to_i
        recent_zset[video.id] = relevance
        n = 1 + Aji.conf['MAX_RECENT_VIDEO_IDS_IN_TRENDING']
        Aji.redis.zremrangebyrank recent_zset.key, 0, -n
      end

      def pop_recent video
        recent_zset.delete video.id
      end

    end
  end
end
