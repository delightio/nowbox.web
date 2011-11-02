module Aji
  class Queues::DistributdRefreshAllChannels
    extend WithDatabaseConnection
    @queue = :refresh_channel

    def self.perform
      # Spread channel population out across a six hour window by channel type.
      # Not only will this distribute more randomly but it will also ease strain
      # on specific APIs.
      Channel.autopopulatable_types.each do |chan_type|
        offset_in_seconds = 6.hours / chan_type.count
        current_time = Time.now

        chan_type.select([:id, :populated_at]).each_with_index do |c, i|
          c.background_refresh_content current_time + offset * i
        end
      end
    end
  end
end
