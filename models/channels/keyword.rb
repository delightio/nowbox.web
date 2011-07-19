module Aji
  module Channels
    # ## Keyword Schema Additions
    # - keywords: Serialized array of strings
    class Keyword < Channel
      serialize :keywords

      def serializable_hash options={}
        h = super
        h["title"] = title || keywords.join(", ")
        h
      end

      def populate
        (1..3).each do |page|
          vids = YouTubeIt::Client.new.videos_by(:query => keywords.join(' '),
                                                 :page => page).videos
          vids.each_with_index do |v, i|
            content_zset[Video.find_or_create_from_youtubeit_video(v).id] = "#{page}#{i}".to_i
          end
        end
        self.populated_at = Time.now
        save
      end
    end
  end
end
