module Aji
  module Queues
    class ExamineVideo
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :examine_video
      
      def self.perform video_id
        # TODO: put it in blacklist right the way
        Aji.redis.sadd Channel.blacklisted_video_ids_key, video_id
      end
    end
  end
end
