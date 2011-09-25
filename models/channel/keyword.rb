module Aji
  # ## Keyword Schema Additions
  # - keywords: Serialized array of strings
  class Channel::Keyword < Channel
    include Aji::TankerDefaults::Channel

    serialize :keywords, Array

    before_create :set_title, :sort_keywords
    after_create :queue_refresh_channel
    def self.to_title words; words.sort.join ", "; end
    def set_title; self.title = title || self.class.to_title(keywords); end
    def sort_keywords; self.keywords = keywords.sort; end


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
      "http://beta.#{Aji.conf['TLD']}/images/icons/tag.png"
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

    def queue_refresh_channel
      Resque.enqueue Aji::Queues::RefreshChannel, self.id
    end

  end
end

