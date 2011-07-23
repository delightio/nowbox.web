module Aji
  module Queues
    class PopulateAllChannels
      @queue = :populate_channel
      def self.perform
        Channel.all.each { |ch| Resque.enqueue PopulateChannel, ch.id }
      end
    end
  end
end
