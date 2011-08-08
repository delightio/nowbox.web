module Aji
  module Channels
    # ## Keyword Schema Additions
    # - keywords: Serialized array of strings
    class Keyword < Channel
      serialize :keywords

      before_create :set_title
      def self.to_title words; words.join ", "; end
      def set_title; self.title = title || self.class.to_title(keywords); end

      def populate
        videos = Macker::Search.new(:keywords => keywords).search
        videos.each_with_index do |v, i|
          content_zset[Video.find_or_create_by_external_id(
            video[:external_id], video).id] = i
        end
        update_attribute :populated_at, Time.now
      end
    end
  end
end

