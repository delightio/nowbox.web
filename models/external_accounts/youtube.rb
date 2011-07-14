module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Youtube Schema Extensions
    # - own_zset: Redis::Objects::SortedSet
    # TODO: Currently overloading ExternalAccount#uid to store youtube
    # username. This is more than likely not the actual Youtube uid so we
    # sould determine what it is and store it in the user_info hash with the
    # other user params.
    class Youtube < ExternalAccount
      include Redis::Objects

      before_create :set_provider

      sorted_set :own_zset
      has_and_belongs_to_many :channels,
        :class_name => 'Channels::YoutubeAccount',
        :join_table => :youtube_youtube_channels,
        :foreign_key => :account_id, :association_foreign_key => :channel_id

      def own_videos limit=-1
        content_video_ids(limit).map { |vid| Video.find vid }
      end

      def own_video_ids limit=-1
        (content_zset.revrange 0, limit).map(&:to_i)
      end

      def username; uid; end

      def profile_uri; "http://www.youtube.com/user/#{uid}"; end

      def set_provider
        provider = 'youtube'
      end

    end
  end
end
