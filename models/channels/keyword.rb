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
      def thumbnail_uri; "http://beta.#{Aji.conf['TLD']}/images/icons/icon-set_nowtrending.png"; end

      def populate
        (1..3).each do |page|
          vids = Aji.youtube_client.videos_by(:query => keywords.join(' '),
                                              :page => page).videos
          vids.each_with_index do |v, i|
            content_zset[Video.find_or_create_from_youtubeit_video(v).id] =
              "#{page}#{i}".to_i
          end
        end
        self.populated_at = Time.now
        save
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
