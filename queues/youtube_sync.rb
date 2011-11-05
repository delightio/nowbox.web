module Aji
  class Queues::SynchronizeWithYoutube
    extend Queues::WithDatabaseConnection

    @queue = :youtube_sync

    def self.perform account_id
      account = Account.find(account_id)

      YoutubeSync.new(account).synchronize!
    end
  end
end
