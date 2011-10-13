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
      searchable_columns = [ :username, :info ]
      sql_string = searchable_columns.map {|c| "lower(#{c}) LIKE ?" }.join(' OR ')
      results = []
      @query.tokenize.each do | q |
        sql = [ sql_string ]
        searchable_columns.count.times { |n| sql << "%#{q}%"}
        results += Account.where sql
      end
      results.uniq # since we search per each keyword
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
        next if usernames.include?(q) || q.split(' ').count > 1
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