module Aji
  module Queues
    module Debug
      class ForcedYoutubeSync
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          youtube_uids = ["dapunster"]
          youtube_uids.each do |yt_uid|
            account = Account::Youtube.find_by_uid yt_uid
            next if account.nil?

            YoutubeSync.new(account).synchronize!
          end
        end

      end
    end
  end
end
