module Aji
  module Queues
    class RefreshAllChannels
      extend WithDatabaseConnection
      @queue = :refresh_channel

      def self.perform
        unless RefreshAllChannels.automatically?
          Aji.log "Automatic channel population is off."
          return
        end

        if RefreshAllChannels.backlogging?
          Aji.log "Skip RefreshAllChannels since #{Resque.size(@queue)} channels are still refreshing."
          return
        end
        # TODO: We would need a different strategy for refreshing all channels.
        [ Channel::Account, Channel::Keyword,
          Channel::FacebookStream, Channel::TwitterStream].each do |ch_class|
            ch_class.all.each { |ch| ch.background_refresh_content }
        end
      end

      def self.automatically?
        flag = Aji.conf['PAUSE_AUTOMATIC_CHANNEL_POPULATION']
        flag.nil? || flag.to_s!='true'
      end

      def self.backlogging?
        Resque.size(@queue) > Channel.count/2
      end
    end
  end
end

