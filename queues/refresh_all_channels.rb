module Aji
  module Queues
    class PopulateAllChannels
      @queue = :populate_channel
      def self.perform
        unless PopulateAllChannels.automatically?
          Aji.log "Automatic channel population is off."
          return
        end
        Channel.all.each { |ch| Resque.enqueue PopulateChannel, ch.id }
      end
      def self.automatically?
        flag = Aji.conf['PAUSE_AUTOMATIC_CHANNEL_POPULATION']
        flag.nil? || flag.to_s!='true'
      end
    end
  end
end
