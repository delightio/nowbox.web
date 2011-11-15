module Aji
  class Queues::DistributedChannelRefresh
    extend Queues::WithDatabaseConnection

    @queue = :refresh_channel

    def self.perform
      Channel.refreshable_types do |channel_type|
        interval = 24.hours / channel_type.count + 1

        channel_type.select(:id).each_with_index do |channel, index|
          channel.background_refresh_content interval * index
        end
      end
    end
  end
end
