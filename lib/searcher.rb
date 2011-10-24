module Aji
  class Searcher

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
      @query = query
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

    def channel_results
      videos_from_keywords = video_results_from_keywords
      unique_authors = videos_from_keywords.map(&:author).uniq
      unique_authors.map &:to_channel
      # sorted = unique_authors.sort {|x,y| y.subscriber_count <=> x.subscriber_count }
      # sorted.map &:to_channel
    end

    def results
      channels = [] # Always return channel objects
      return channels unless Searcher.enabled?

      channels += account_results.map(&:to_channel)
      channels += channel_results

      # only show unique, available channels, sorted by subscriber count
      channels = channels.uniq
      channels = channels.select {|ch| ch.available?}
      channels = channels.sort do |x,y|
        y.accounts.first.subscriber_count <=> x.accounts.first.subscriber_count
      end
      channels = channels.first(5)

      # TODO: hack to make NowPopular searchable
      splits = @query.split ' '
      if (splits.include? "now") || (splits.include? "popular")
        channels = [Channel.trending] + channels
      end

      channels.each { |ch| ch.background_refresh_content }
      channels
    end

  end
end