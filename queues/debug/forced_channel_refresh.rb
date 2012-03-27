AccountName = "freddiew"

module Aji
  module Queues
    module Debug
      class ForcedChannelRefresh
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          account = Account::Youtube.find_by_username AccountName
          channel = account.to_channel

          # Remove cached version so it will grab from account again
          channel.clear_cached_content_video_ids
        end

      end
    end
  end
end

module Aji
  module Queues
    module Debug
      class RemoveNewVideos
        extend WithDatabaseConnection
        @queue = :debug

        def self.perform
          account = Account::Youtube.find_by_username AccountName
          channel = account.to_channel

          # remove first 3 videos
          Aji.log "Removing 3 videos from Channel[#{channel.title}]"
          channel.content_videos(3).each {|v| Aji.log v.title }
          Aji.redis.zremrangebyrank channel.content_zset.key, -3, -1
          Aji.log "Top 3 videos are now:"
          channel.content_videos(3).each {|v| Aji.log v.title }

          # Force a long expiration so we won't accidentally refresh the channel
          Aji.redis.expire channel.content_zset.key, 1.hours
        end

      end
    end
  end
end
