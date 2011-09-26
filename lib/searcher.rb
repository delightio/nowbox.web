module Aji
  class Searcher

    def self.enabled?
      false
      # RACK_ENV!='test'
    end

    def initialize query
      @query = query
    end

    def channel_results
      Channel.search_tank @query
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
        account = Account::Youtube.new :uid => q
        accounts << account if account.existing?
      end

      channels = channel_results + accounts.map(&:to_channel)
      channels = channels.uniq
      channels.each { |ch| Resque.enqueue Queues::RefreshChannel, ch.id }
      channels
    end

  end
end