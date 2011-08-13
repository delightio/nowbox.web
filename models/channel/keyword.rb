module Aji
  # ## Keyword Schema Additions
  # - keywords: Serialized array of strings
  class Channel::Keyword < Channel
    serialize :keywords, Array

    before_create :set_title, :sort_keywords
    def self.to_title words; words.sort.join ", "; end
    def set_title; self.title = title || self.class.to_title(keywords); end
    def sort_keywords; self.keywords = keywords.sort; end

    # LH 225
    def thumbnail_uri
      "http://beta.#{Aji.conf['TLD']}/images/icons/icon-set_nowtrending.png"
    end

    def refresh_content force=false
      vhashes = Macker::Search.new(:keywords => keywords).search
      vhashes.each_with_index do |vhash, i|
        video = Video.find_or_create_by_external_id(
          vhash[:external_id], vhash)
          content_zset[video.id] = i
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

