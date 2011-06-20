module Aji
  module Queues
    # This class is runs `Channel#populate` on a single channel. It's a good
    # way to parallelize the last step of channel creation jobs.
    class PopulateChannel
      # Specify a class attribute `queue` which resque uses for job control.
      @@queue = :normal

      def self.perform channel_id
        Channel.find(channel_id).populate
      end
    end
  end
end
