module Aji
  module Macker
    class Youtube
      def self.fetch source_id
        youtube_it_to_hash client.video_by source_id

      rescue NoMethodError => e
        raise unless e.message =~ /undefined method `elements' for nil:NilClass/
        fail Macker::FetchError, "unable to fetch youtube:#{source_id}"
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
        category_from_youtube = video.categories.first
        if category_from_youtube
          category = Category.find_or_create_by_raw_title(
            category_from_youtube.label, :title => category_from_youtube.term)
        else
          category = Category.find_or_create_by_raw_title "*** undefined ***"
        end
        author = Account::Youtube.find_or_create_by_uid(video.author.name)
        {
          :title => video.title,
          :external_id => video.video_id.split(':').last,
          :description => video.description,
          :duration => video.duration,
          :viewable_mobile => (not video.noembed),
          :view_count => video.view_count,
          :category_id => category.id,
          :author_id => author.id,
          :published_at => video.published_at,
          :source => 'youtube'
        }
      end
    end
  end
end
