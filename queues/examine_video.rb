module Aji
  module Queues
    class ExamineVideo
      extend WithDatabaseConnection
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :examine_video

      def self.perform video_id
        video = Video.find_by_id video_id
        video.blacklist if video # TODO
      end
    end
  end
end
