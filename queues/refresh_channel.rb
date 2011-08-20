module Aji
  module Queues
    # This class is runs `Channel#populate` on a single channel. It's a good
    # way to parallelize the last step of channel creation jobs.
    class RefreshChannel
      extend WithDatabaseConnection
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :refresh_channel

      def self.perform channel_id
        Channel.find(channel_id).refresh_content
      end
    end
  end
end
