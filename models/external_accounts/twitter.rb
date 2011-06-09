module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Twitter Schema Extensions
    # - tweeted_zset: Redis::Objects::SortedSet
    class Twitter < ExternalAccount
      include Redis::Objects

      sorted_set :tweeted_zset

      def tweeted_videos
        Video.find tweeted.members
      end
    end
  end
end
