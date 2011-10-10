module Aji
  module Queues
    class ExamineVideo
      extend WithDatabaseConnection
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :examine_video

      def self.perform args
        video = Video.find_by_id args[:video_id]
        unless video.nil?
          video.blacklist
          author = video.author # TODO: !law of demeter
          author.blacklist_repeated_offender
        end
      end
    end
  end
end
