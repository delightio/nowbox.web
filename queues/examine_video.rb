module Aji
  module Queues
    class ExamineVideo
      extend WithDatabaseConnection
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :examine_video

      def self.perform args
        video = Video.find_by_id args[:video_id]
        unless video.nil?
Aji.log "Video[#{video.id}] getting blacklisted in ExamineVideo"
return
          video.blacklist
          bad_count = Video.where(
            "author_id = ? AND blacklisted_at IS NOT NULL", video.author.id).
            count
          video.author.blacklist if bad_count >= 3
        end
      end
    end
  end
end
