module Aji
  module Queues
    module Debug
      class FakeChannelChanges
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          youtube_uids = ["dapunster"]
          youtube_uids.each do |yt_uid|
            account = Account::Youtube.find_by_uid yt_uid
            user = account.user
            next if account.nil? or user.nil?

            # Remove a channel
            del = user.subscribed_channels.first
            if del
              user.unsubscribe del
              Aji.log "Unsubscribed: #{del.id}, #{del.title}"
            end

            # Add a channel
            ch = Channel.find 862
            if ch
              user.subscribe ch
              Aji.log "Subscribed: #{ch.id}, #{ch.title}"
            end

          end
        end

      end
    end
  end
end
