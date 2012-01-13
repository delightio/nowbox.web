module Aji
  class Searcher
    attr_reader :query

    def self.enabled?
      RACK_ENV!='test'
    end

    def self.minimun_video_count
      5
    end

    def self.max_video_count_from_keyword_search
      20
    end

    def initialize query
      query.gsub! "\"", ""
      query.gsub! "\'", ""
      @query = query.strip
    end

    def authors_from_channel_search
      uids = YoutubeAPI.new.channel_search @query
      uids.map {|uid| Account::Youtube.find_or_create_by_lower_uid uid }
    end

    def unique_and_sorted authors
      authors.compact!
      authors.reject!{ |a| a.username.nil? }
      authors.uniq!
      authors.select! &:available?
      authors.sort! do |x,y|
        y.subscriber_count <=> x.subscriber_count
      end
    end

    def results
      return [] unless Searcher.enabled?
      return [] if @query.empty?

      filtered_authors = unique_and_sorted authors_from_channel_search
      channels = filtered_authors.first(10).map(&:to_channel)

      # TODO: hack to make NowPopular searchable
      # splits = @query.split ' '
      # if (splits.include? "now") || (splits.include? "popular")
      #   channels = [Channel.trending] + channels
      # end

      channels.each { |ch| ch.background_refresh_content }
      channels
    end

  end
end
