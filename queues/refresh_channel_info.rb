module Aji
  module Queues
    class RefreshChannelInfo
      extend WithDatabaseConnection

      @queue = :refresh_channel_info

      def self.perform channel_id
        channel = Channel.find_by_id channel_id
        return if channel.nil? || channel.class!=Channel::Account
        channel.accounts.each do |account|
          if account.class == Account::Youtube &&
            !account.refreshed?
            account.refresh_info
            Aji.log "  Channel[#{channel_id}] Account[#{account.id}] refreshed"
          end
        end
      end
    end
  end
end
