module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Youtube Schema Extensions
    # - own_zset: Redis::Objects::SortedSet
    # TODO: Currently overloading ExternalAccount#uid to store youtube
    # username. This is more than likely not the actual Youtube uid so we
    # sould determine what it is and store it in the user_info hash with the
    # other user params.
    class Youtube < ExternalAccount
      has_and_belongs_to_many :channels,
        :class_name => 'Channels::YoutubeAccount',
        :join_table => :youtube_youtube_channels,
        :foreign_key => :account_id, :association_foreign_key => :channel_id

      def username; uid; end
      def profile_uri; "http://www.youtube.com/user/#{username}"; end
      def thumbnail_uri # LH #120
        Video.find(content_video_ids(1).first).thumbnail_uri
      end

    end
  end
end
