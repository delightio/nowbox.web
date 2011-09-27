module Aji
  # ## Keyword Schema Additions
  # - keywords: Serialized array of strings
  class Channel::Keyword < Channel
    serialize :keywords, Array

    before_create :set_title, :sort_keywords

    after_create :background_refresh_content

    def self.to_title words
      words.sort.join ", "
    end

    def set_title
      self.title = title || self.class.to_title(keywords)
    end

    def sort_keywords
      self.keywords = keywords.sort
    end

    # TODO LH 355
    def self.find_or_create_by_keywords words
      c = self.search_helper words.join(',')
      return c.first unless c.empty?
      self.create :keywords => words
    end

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/tag.png"
    end

    def refresh_content force=false
      super force do |new_videos|
        vhashes = Macker::Search.new(:keywords => keywords).search
        vhashes.each_with_index do |vhash, i|
          video = Video.find_or_create_by_external_id(
            vhash[:external_id], vhash)
          new_videos << video
          push video, i
        end
      end
    end

    def self.searchable_columns; [:title]; end
  end
end

