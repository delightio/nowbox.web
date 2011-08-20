module Aji
  module Queues
    class RefreshAllChannels
      extend WithDatabaseConnection
      @queue = :refresh_channel
      def self.queue; @queue; end # to check queue depth

      def self.perform
        unless RefreshAllChannels.automatically?
          Aji.log "Automatic channel population is off."
          return
        end
        if Resque.size(@queue) > Channel.count/2
          Aji.log "Skip RefreshAllChannels since #{Resque.size(@queue)} channels are still refreshing."
          return
        end
        Channel.all.each { |ch| Resque.enqueue RefreshChannel, ch.id }
      end

      def self.automatically?
        flag = Aji.conf['PAUSE_AUTOMATIC_CHANNEL_POPULATION']
        flag.nil? || flag.to_s!='true'
      end
    end
  end
end
