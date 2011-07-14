module Aji
  module Queues
    class ExamineVideo
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :examine_video

      def self.perform video_id
        Video.blacklist_id video_id  # TODO
      end
    end
  end
end
