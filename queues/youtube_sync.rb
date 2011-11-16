module Aji
  class Queues::SynchronizeWithYoutube
    extend Queues::WithDatabaseConnection

    @queue = :youtube_sync

    def self.perform account_id, disable_resync = false
      account = Account.find(account_id)

      YoutubeSync.new(account).synchronize! disable_resync
    end
  end
end
