module Aji
  module Macker
    class Youtube
      def self.fetch source_id
        video = client.video_by source_id
        {
          :title => video.title,
          :description => video.description,
          :duration => video.duration,
          :viewable_mobile => (not video.noembed),
          :view_count => video.view_count,
          :published_at => video.published_at,
          :author_username => video.author.name
        }
      end

      private
      def self.client
        # The empty hash is to shut the erroneous deprecation warning up.
        @client ||= YouTubeIt::Client.new({})
      end
    end
  end
end
