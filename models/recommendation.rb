module Aji
  class Recommendation

    def initialize user
      @user = user
    end

    def videos
      recommended = []
      @user.subscribed_channels.each do |channel|
        channel.content_videos(10).each do |video|
          recommended << video
        end
      end
      recommended.sample(50)
    end

    def refresh_videos
      destination = @user.recommended_channel
      return if destination.recently_populated?

      videos.each { |v| destination.push v }
      destination.update_attribute :populated_at, Time.now
    end

    def background_refresh
      Resque.enqueue_in 1.hour, Queues::RefreshRecommendedVideos, @user.id
    end

  end
end