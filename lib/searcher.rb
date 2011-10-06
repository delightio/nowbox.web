module Aji
  class Searcher

    def self.enabled?
      RACK_ENV!='test'
    end

    def self.minimun_video_count
      5
    end

    def initialize query
      @query = query
    end

    def account_results
      Account.search_tank @query
    end

    def results
      # Search existing accounts on our db or on external network.
      # Search existing channels
      # Return uniq channels
      # Enqueue each channel within result

      return [] unless Searcher.enabled?
      accounts = account_results
      usernames = accounts.map &:username
      @query.tokenize.each do |q|
        next if usernames.include? q
        new_account = Account::Youtube.create_if_existing q
        accounts << new_account unless new_account.nil?
      end

      channels = accounts.map(&:to_channel)

      # TODO: hack to make NowPopular searchable
      splits = @query.split ' '
      if (splits.include? "now") || (splits.include? "popular")
        channels = [Channel.trending] + channels
      end

      channels = channels.uniq
      channels.each { |ch| ch.background_refresh_content }
      channels
    end

  end
end