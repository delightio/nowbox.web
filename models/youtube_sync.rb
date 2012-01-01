module Aji
  class YoutubeSync
    attr_reader :user, :account

    def initialize account, min_delay_between_calls=0
      @account, @user = account, account.user
      @min_delay_between_calls = min_delay_between_calls
    end

    def synchronize! disable_resync = false
      return if account.nil? or user.nil?

      user.without_hooks! do
        sync_subscribed_channels
        sync_watch_later
        sync_favorites
      end

      enqueue_resync unless disable_resync
      account.synchronized_at = Time.now
      account.save
    end

    def push_and_synchronize! disable_resync = false
      # Disable mass subscription push per YouTube API team request.
      # push_subscribed_channels
      # push_favorite_videos
      # push_watch_later_videos

      synchronize! disable_resync
    end


    def push_subscribed_channels
      user.youtube_channels.each do |c|
        unless youtube_subscriptions.include? c
          account.api.subscribe_to c.youtube_id
          @youtube_subscriptions << c
        end
      end
    end

    def push_watch_later_videos
      user.queued_videos.select{ |v| v.source == :youtube }.each do |v|
        unless youtube_watch_later_videos.include? v
          account.api.add_to_watch_later v.external_id
          @youtube_watch_later_videos << v
        end
      end
    end

    def push_favorite_videos
      user.favorite_videos.select{ |v| v.source == :youtube }.each do |v|
        unless youtube_favorite_videos.include? v
          account.api.add_to_favorites v.external_id
          @youtube_favorite_videos << v
        end
      end
    end

    def sync_subscribed_channels
      youtube_subscriptions.each do |c|
        c.background_refresh_content
        user.subscribe c
      end
      delay
    end

    def sync_watch_later
      youtube_watch_later_videos.each do |v|
        user.enqueue_video v, Time.now
      end
      delay
    end

    def sync_favorites
      youtube_favorite_videos.each do |v|
        user.favorite_video v, Time.now
      end
      delay
    end

    def youtube_subscriptions
      @youtube_subscriptions ||= if (subs = account.api.subscriptions)
                                   subs
                                 else
                                   []
                                 end
    end

    def youtube_watch_later_videos
      @youtube_watch_later_videos ||= if (laters = account.api.watch_later_videos)
                                        laters
                                      else
                                        []
                                      end
    end

    def youtube_favorite_videos
      @youtube_favorite_videos ||= if (favs = account.api.favorite_videos)
                                     favs
                                   else
                                     []
                                   end
    end

    def enqueue_resync
      unless account.synchronized_at && account.synchronized_at > 30.minutes.ago
        Resque.enqueue_in 1.day, Queues::SynchronizeWithYoutube, account.id
      end
    end

    def background_synchronize! disable_resync = false
      Resque.enqueue Queues::SynchronizeWithYoutube, account.id, disable_resync
    end

    def background_push_and_synchronize! disable_resync = false
      Resque.enqueue Queues::SynchronizeWithYoutube, account.id,
        disable_resync, :push_first
    end

    def delay
      unless @min_delay_between_calls==0
        sleep random_cooldown
      end
    end

    def random_cooldown
      @min_delay_between_calls + rand(@min_delay_between_calls*2)
    end
    private :delay, :random_cooldown
  end
end
