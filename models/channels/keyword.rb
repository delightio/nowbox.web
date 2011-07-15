module Aji
  module Channels
    # ## Keyword Schema Additions
    # - keywords: Serialized array of strings
    class Keyword < Channel
      serialize :keywords

      def serializable_hash options={}
        h = super
        h["title"] = keywords.join ", "
        h
      end

      def populate
        videos = VideoSource::Youtube.search keywords
        videos.each_with_index do |v, i|
          push v, i
        end
      end
    end
  end
end
