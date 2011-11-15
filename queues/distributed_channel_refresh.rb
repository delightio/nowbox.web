module Aji
  class Queues::DistributedChannelRefresh
    extend Queues::WithDatabaseConnection

    @queue = :refresh_channel

    def self.perform
      Channel.refreshable_types.each do |channel_type|
        next if channel_type.count == 0

        interval = 24.hours / channel_type.count + 1
        puts interval

        channel_type.select(:id).each_with_index do |channel, index|
          channel.background_refresh_content interval * index
        end
      end
    end
  end
end
