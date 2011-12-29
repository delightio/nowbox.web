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

    def account_results_from_indextank
      Account.search_tank @query+"*"
    end

    def account_results
      # Check with exisiting accounts we have seen so far.
      # Also check Youtube for exact username match
      accounts = account_results_from_indextank
      usernames = accounts.map &:username
      @query.tokenize.each do |q|
        next if usernames.include?(q) || q.split(' ').count > 1
        new_account = Account::Youtube.create_if_existing q
        accounts << new_account unless new_account.nil?
      end
      accounts
    end

    def video_results_from_keywords
      YoutubeAPI.new.keyword_search(
        @query, Searcher.max_video_count_from_keyword_search)
    end

    def authors_from_keyword_search
      videos_from_keywords = video_results_from_keywords
      unique_authors = videos_from_keywords.map(&:author)
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

      authors = account_results + authors_from_keyword_search
      filtered_authors = unique_and_sorted authors
      channels = filtered_authors.first(7).map(&:to_channel)

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
