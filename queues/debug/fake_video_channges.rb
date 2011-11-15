module Aji
  module Queues
    module Debug
      class FakeVideoChanges
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          youtube_uids = ["dapunster"]
          youtube_uids.each do |yt_uid|
            account = Account::Youtube.find_by_uid yt_uid
            user = account.user

            if account.nil?
              Aji.log "Can't find YouTuber: #{yt_uid}"
              next
            end
            if user.nil?
              Aji.log "Can't find user associated with: #{yt_uid}"
              next
            end

            # Favorites
            del = user.favorite_videos.first
            if del
              user.unfavorite_video del
              Aji.log "Removed from Favorites: #{del.id}, #{del.title}"
            end

            new_fav = Video.first
            user.favorite_video new_fav, 3.hours.ago
            Aji.log "Added to Favorites: #{new_fav.id}, #{new_fav.title}"

            # Watch Later
            del = user.queued_videos.sample
            if del
              user.dequeue_video del
              Aji.log "Removed from Watch Later: #{del.id}, #{del.title}"
            end

            new_wl = Video.first :offset=>100
            user.queue_video new_wl, 3.hours.ago
            Aji.log "Added to Watch Later: #{new_wl.id}, #{new_wl.title}"
          end
        end

      end
    end
  end
end
