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
        channel = Channel.find channel_id
        channel.refresh_content
        Aji.log :INFO, "#{channel.class}[#{channel_id}]#refresh_content took #{Time.now-start} s."
      end
    end
  end
end
