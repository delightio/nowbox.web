module Aji
  module Queues
    # This class is runs `Channel#populate` on a single channel. It's a good
    # way to parallelize the last step of channel creation jobs.
    class RefreshChannel
      extend WithDatabaseConnection
      # Specify a class attribute `queue` which resque uses for job control.
      @queue = :refresh_channel

      def self.perform channel_id
        start = Time.now
        Channel.find(channel_id).refresh_content
        Aji.log :INFO, "Channel[#{channel_id}]#refresh_content took #{Time.now-start} s."
      end
    end
  end
end
