module Aji
  module Queues
    class RefreshTrendingChannels
      extend WithDatabaseConnection
      @queue = :refresh_channel

      def self.perform
        Channel::Trending.all.each { |ch| ch.background_refresh_content }
      end

    end
  end
end
