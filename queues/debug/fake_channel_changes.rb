module Aji
  module Queues
    module Debug
      class FakeChannelChanges
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          youtube_uids = ["testnb1"]
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
            chs = Channel.first(200)
            begin
              ch = chs.sample
            end until ch.accounts.count==1 && !user.subscribed?(ch)
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
