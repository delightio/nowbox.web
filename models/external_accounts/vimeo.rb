module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Vimeo Schema Extensions
    # - own_zset: Redis::Objects::SortedSet
    class Vimeo < ExternalAccount
      include Redis::Objects

      sorted_set :own_zset

      def own_videos limit=-1
        content_video_ids(limit).map { |vid| Video.find vid }
      end

      def own_video_ids limit=-1
        (content_zset.revrange 0, limit).map(&:to_i)
      end

    end
  end
end

