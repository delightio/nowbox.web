require 'net/http'
require 'json'

module Aji
  module Channels
    class Trending < Channel
      def populate args={}
        url = args[:url] || "nowmov.com"
        path = args[:path] || "/live/videos"
        limit = args[:limit] || 100
        # Target is mobile since we'll always be going to the iPad
        params = "?target=mobile&limit=#{limit.to_i}"
        path = path + params
        response = Net::HTTP.get url, path
        video_hashes = JSON.parse response
        video_hashes.each_with_index do |video_hash, index|
          youtube_account = ExternalAccounts::Youtube.find_or_create_from_uid(
            video_hash[:author_username], :provider => "youtube")

          video = Aji::Video.find_or_create_from_external_id(
            video_hash[:service_external_id],
            :external_account => youtube_account,
            :source           => video_hash[:service_name],
            :title            => video_hash[:title],
            :description      => video_hash[:description],
            :viewable_mobile  => true) # since we specified mobile target.
          # Place the video in the channel.
          content_zset[video.id] = index
        end
      end

      # There should only ever be one trending channel. This class method
      # fetches it.
      def Trending.channel; Trending.first; end
    end
  end
end
