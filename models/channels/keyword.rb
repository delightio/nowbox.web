module Aji
  module Channels
    # ## Keyword Schema Additions
    # - keywords: Serialized array of strings
    class Keyword < Channel
      serialize :keywords

      before_create :set_title, :sort_keywords
      def self.to_title words; words.sort.join ", "; end
      def set_title; self.title = title || self.class.to_title(keywords); end
      def sort_keywords; self.keywords = keywords.sort; end

      # LH 225
      def thumbnail_uri
        "http://beta.#{Aji.conf['TLD']}/images/icons/icon-set_nowtrending.png"
      end

      def populate
        videos = Macker::Search.new(:keywords => keywords).search
        videos.each_with_index do |video, i|
          video[:author] = Account::Youtube.find_or_create_by_uid(
            video.delete :author_username)
          content_zset[Video.find_or_create_by_external_id(
            video[:external_id], video).id] = i
        end
        update_attribute :populated_at, Time.now
      end

      def self.searchable_columns; [:title]; end
      def self.search_helper query
        results = super
        results << self.create(:keywords => query.tokenize.sort) if results.empty?
        results
      end
    end
  end
end

