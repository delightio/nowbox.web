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

    def self.search_helper query
      searchable_columns = [:title]
      sql_string = searchable_columns.map {|c| "lower(#{c}) LIKE ?" }.join(' OR ')
      results = []
      query.tokenize.each do | q |
        sql = [ sql_string ]
        searchable_columns.count.times { |n| sql << "%#{q}%"}
        results += self.where sql
      end
      results.uniq # since we search per each keyword
    end

    def self.find_or_create_by_query query
      c = self.search_helper query
      return c.first unless c.empty?
      self.create :keywords => query.tokenize
    end

    def thumbnail_uri
      "http://#{Aji.conf['TLD']}/images/icons/tag.png"
    end

    def refresh_content force=false
      super force do |new_videos|
        api.keyword_search(keywords).each_with_index do |video, i|
          new_videos << video
          push video, i
        end
      end
    end

    def api
      @api ||= VideoAPI.new
    end
  end
end

