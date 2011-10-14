module Aji
  class Video < ActiveRecord::Base
    def has_nil_author?
      populated? && author.nil?
    end
  end

  module Queues
    class FixPopulatedVideo
      extend WithDatabaseConnection
      @queue = :examine_video

      def self.perform video_id
        video = Video.find_by_id video_id
        unless video.nil?
          if video.has_nil_author?
            Aji.log "  Fixing Video[#{video.id}]..."
            Aji.redis.zadd "PopulatedVideosWithNilAuthors", Time.now.to_i, video.id
            video.update_attribute :populated_at, nil
            video.populate do |v|
              Aji.log "    Video[#{v.id}] fixed: new author id: #{v.author.id}"
            end
          end
        end
      end
    end
  end
end
