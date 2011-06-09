module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Youtube Schema Extensions
    # - own_zset: Redis::Objects::SortedSet
    class Youtube
			sorted_set 
      has_and_belongs_to_many :channels,
        :class_name => 'Channels::YoutubeAccount',
        :join_table => :youtube_youtube_channels,
        :foreign_key => :account_id, :association_foreign_key => :channel_id
    end
  end
end
