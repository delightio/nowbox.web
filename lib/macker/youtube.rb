module Aji
  module Macker
    class Youtube
      def self.fetch source_id
        youtube_it_to_hash client.video_by source_id

      rescue NoMethodError => e
        raise unless e.message =~ /undefined method `elements' for nil:NilClass/
        fail Macker::FetchError, "unable to fetch youtube:#{source_id}",
          'youtube', source_id
      end

      def self.search type, values
        self.send "#{type}_search".to_sym, values
      end

      private
      def self.client
        # The empty hash is to shut the erroneous deprecation warning up.
        @client ||= YouTubeIt::Client.new({})
      end

      def self.keywords_search keywords
        videos = Array.new
        (1..4).each do |page|
          videos.concat client.videos_by(:query => keywords.join(' '),
            :page => page).videos.map{ |v| youtube_it_to_hash v }
        end
        videos
      end

      def self.author_search author
        videos = client.videos_by(:user => author, :order_by => 'published').
          videos.map{ |v| youtube_it_to_hash v }
      end

      def self.youtube_it_to_hash video
        {
          :title => video.title,
          :external_id => video.video_id.split(':').last,
          :description => video.description,
          :duration => video.duration,
          :viewable_mobile => (not video.noembed),
          :view_count => video.view_count,
          :published_at => video.published_at,
          :author_username => video.author.name,
          :source => 'youtube'
        }
      end
    end
  end
end
