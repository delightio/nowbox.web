module Aji
# A module encapsulating the logic for owning a sorted_set of videos.
  module HasOwnVideos
    include Redis::Objects

    sorted_set :zset

    def videos limit=-1
      video_ids(limit).map{ |id| Video.find id }
    end

    def video_ids limit=-1

    end
  end
end
