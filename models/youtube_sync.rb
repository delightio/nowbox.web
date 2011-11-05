module Aji
  class YoutubeSync
    attr_reader :user, :account

    def initialize account
      @account, @user = account, account.user
    end

    def synchronize!
      sync_subscribed_channels
      sync_watched_later
      sync_favorites
      enqueue_resync
    end

    def sync_subscribed_channels

    end

    def sync_watched_later

    end

    def sync_favorites

    end

    def enqueue_resync
      Resque.enqueue_in 1.day, Queues::YoutubeSync, account.id
    end
  end
end
