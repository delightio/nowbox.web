module Aji
  module Mixins
    module RecentVideos
      # We need to add the following BEFORE including this mixins because
      # Redis::Objects expect a database ID to generate a unique redis key
      #
      # ************************
      # include Redis::Objects
      # ************************
      def self.included klass
        klass.sorted_set :recent_zset
      end

      def recent_videos limit=0
        recent_video_ids(limit).map { |vid| Video.find_by_id vid }.compact
      end

      def recent_video_ids limit=0
        (recent_zset.revrange 0, (limit-1)).map(&:to_i)
      end

      def recent_video_id_count
        # TODO LH #346 content_zset.size always returns 0
        #   before any calls to content_video_ids
        recent_video_ids.count
      end

      def push_recent video, relevance=Time.now.to_i
        recent_zset[video.id] = relevance
        n = 1 + Aji.conf['MAX_RECENT_VIDEO_IDS_IN_TRENDING']
        Aji.redis.zremrangebyrank recent_zset.key, 0, -n
      end

      def pop_recent video
        recent_zset.delete video.id
      end

      def recent_relevance_of video
        recent_zset.score video.id
      end

      def increment_relevance_of_recent_video video, significance
        Aji.redis.zincrby recent_zset.key, significance, video.id
      end

      # min_relevance should not be 0 as we are applying a geometric decay
      def geometric_decay_relevance_in_all_recent_videos by_percent, min_relevance=1
        recent_video_ids.each do |vid|
          original = recent_zset.score vid
          recent_zset[vid] = original * (100-by_percent) / 100
        end
        Aji.redis.zremrangebyscore recent_zset.key, "-inf", min_relevance
      end

    end
  end
end
