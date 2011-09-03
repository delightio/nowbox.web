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
      def content_video_ids limit=0
        (content_zset.revrange 0, (limit-1)).map(&:to_i)
      end

      def content_videos limit=0
        content_video_ids(limit).map { |vid| Video.find vid }
      end

      def content_video_id_count
        # TODO LH #346 content_zset.size always returns 0
        #   before any calls to content_video_ids
        content_video_ids.count
      end

      def content_video_ids_rev limit=0
        (content_zset.range 0, (limit-1)).map(&:to_i)
      end

      def content_videos_rev limit=0
        content_video_ids_rev(limit).map { |vid| Video.find vid }
      end

      def relevance_of video
        content_zset.score video.id
      end

      # Push a video into the channel's content.
      def push video, relevance=Time.now.to_i
        content_zset[video.id] = relevance
      end

      def pop video
        content_zset.delete video.id
      end

      def truncate limit
        content_zset.remrangebyrank 0, -(1+limit)
      end

      def content_zset_ttl; 15.minutes; end

    end
  end
end
