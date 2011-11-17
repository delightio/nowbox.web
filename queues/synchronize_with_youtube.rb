module Aji
  class Queues::SynchronizeWithYoutube
    extend Queues::WithDatabaseConnection

    @queue = :youtube_sync

    def self.perform account_id, disable_resync = false, push_first = false
      account = Account.find(account_id)

      if push_first
        YoutubeSync.new(account).push_and_synchronize! disable_resync
      else
        YoutubeSync.new(account).synchronize! disable_resync
      end
    end
  end
end
