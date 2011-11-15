module Aji
  module Queues
    module Debug
      class ForcedYoutubeSync
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          youtube_uids = ["testnb1"]
          youtube_uids.each do |yt_uid|
            account = Account::Youtube.find_by_uid yt_uid
            if account.nil?
              Aji.log "Can't find YouTuber: #{yt_uid}"
              next
            end

            YoutubeSync.new(account).synchronize!
          end
        end

      end
    end
  end
end
