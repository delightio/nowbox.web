module Aji
  module Queues
    class RefreshAllChannels
      @queue = :populate_channel
      def self.perform
        unless RefreshAllChannels.automatically?
          Aji.log "Automatic channel population is off."
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
