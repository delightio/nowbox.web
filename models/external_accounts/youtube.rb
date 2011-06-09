module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Youtube Schema Extensions
    # - own_zset: Redis::Objects::SortedSet
    class Youtube < ExternalAccount
      include Redis::Objects

			sorted_set :own_zset
      has_and_belongs_to_many :channels,
        :class_name => 'Channels::YoutubeAccount',
        :join_table => :youtube_youtube_channels,
        :foreign_key => :account_id, :association_foreign_key => :channel_id

      def own_videos
        Video.find(own_zset.members)
      end
    end
  end
end
