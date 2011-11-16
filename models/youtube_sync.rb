module Aji
  class YoutubeSync
    attr_reader :user, :account

    def initialize account
      @account, @user = account, account.user
    end

    def synchronize! disable_resync = false
      return if account.nil? or user.nil?

      user.suppress_hooks! do
        sync_subscribed_channels
        sync_watch_later
        sync_favorites
      end

      enqueue_resync unless disable_resync
      account.synchronized_at = Time.now
      account.save
    end

    def sync_subscribed_channels
      youtube_subscriptions.each do |c|
        c.background_refresh_content
        user.subscribe c
      end

      user.youtube_channels.each do |c|
        unless youtube_subscriptions.include? c
          user.unsubscribe c
        end
      end
    end

    def sync_watch_later
      youtube_watch_later_videos.each do |v|
        user.enqueue_video v, Time.now
      end

      user.queued_videos.select{ |v| v.source == :youtube }.each do |v|
        unless youtube_watch_later_videos.include? v
          user.dequeue_video v
        end
      end
    end

    def sync_favorites
      youtube_favorite_videos.each do |v|
        user.favorite_video v, Time.now
      end

      user.favorite_videos.select{ |v| v.source == :youtube }.each do |v|
        unless youtube_favorite_videos.include? v
          user.unfavorite_video v
        end
      end
    end

    def youtube_subscriptions
      @youtube_subscriptions ||= account.api.subscriptions
    end

    def youtube_watch_later_videos
      @youtube_watch_later_videos ||= account.api.watch_later_videos
    end

    def youtube_favorite_videos
      @youtube_favorite_videos ||= account.api.favorite_videos
    end

    def enqueue_resync
      unless account.synchronized_at && account.synchronized_at > 30.minutes.ago
        Resque.enqueue_in 1.day, Queues::SynchronizeWithYoutube, account.id 
      end
    end

    def background_synchronize! disable_resync = false
      Resque.enqueue Queues::SynchronizeWithYoutube, account.id, disable_resync
    end
  end
end
