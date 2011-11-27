module Aji
  module Queues
    class RefreshRecommendedVideos
      extend WithDatabaseConnection
      @queue = :recommendation

      def self.perform user_id
        user = User.find_by_id user_id
        return if user.nil?

        Recommendation.new(user).refresh_videos
      end
    end
  end
end
