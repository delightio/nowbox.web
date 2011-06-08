require 'net/http'
require 'json'

module Aji
  module Channels
    class TrendingChannel < Channel
      def populate args={}
        url = args[:url] || "nowmov.com"
        path = args[:path] || "/live/videos"
        limit = args[:limit] || 100
        params = "?target=mobile&limit=#{limit.to_i}" # since it's always going to be iPad
        path = path + params
        response = Net::HTTP.get url, path
        nowmov_hashes = JSON.parse response
        nowmov_hashes.each_with_index do |nowmov_hash, index|
                          #  nowmov                     aji
          mapping_nw_aji = {:service_name           => :video_source,
                            :author_username        => :screen_name,
                            :service_external_id    => :external_id,
                            :service_name           => :source,
                            :title                  => :title,
                            :description            => :description }
          h={}; mapping_nw_aji.each_pair{ |nw,aji| h[aji] = nowmov_hash[nw] }
          h[:viewable_mobile] = true # since we asked for mobile target
          new_video = Video.find_or_create h # TODO: how do we generate author as well?
          videos[new_video.id] = index
        end
      end
    end
  end
end
