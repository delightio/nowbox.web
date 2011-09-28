module Aji
  class YoutubeAPI

    @@client ||= YouTubeIt::Client.new {}

    def author_info author_id
      DataGrabber.new author_id
    end

    def video_info youtube_id
      youtube_it_to_hash client.video_by youtube_id
    end

    def video youtube_id
      youtube_it_to_video client.video_by youtube_id
    end

    def youtube_it_to_hash video
      if youtube_category = video.categories.first
        category = Category.find_by_raw_title youtube_category.label
        category ||= Category.new :raw_title => youtube_category.label,
          :title => youtube_category.term
      else
        category = Category.undefined
      end

      author = Account::Youtube.find_by_uid(video.author.name)
      author ||= Account::Youtube.new :uid => video.author.name

      {
        :title => video.title,
        :external_id => video.video_id.split(':').last,
        :description => video.description,
        :duration => video.duration,
        :viewable_mobile => (not video.noembed),
        :view_count => video.view_count,
        :category => category,
        :author => author,
        :published_at => video.published_at,
        :source => 'youtube',
        :populated_at => Time.now
      }
    end

    def youtube_it_to_video video
      Video.new youtube_it_to_hash video
    end

    private
    def client
      @@client
    end

    class DataGrabber
      def initialize youtube_uid
        @youtube_uid = youtube_uid
        @feed_url =
          "http://gdata.youtube.com/feeds/api/users/#{youtube_uid}?alt=json&v=2"
        @data = get_data_from_youtube
      end

      def description
        @data.fetch('yt$aboutMe',{}).fetch('$t', "")
      end

      def profile_uri
        link = @data.fetch('link',[]).find do |link_hash|
          link_hash['rel'] == 'alternate'
        end
        if link then link['href'] else "" end
      end

      def thumbnail_uri
        @data.fetch("media$thumbnail", {}).fetch('url', "")
      end

      def realname
      first_name = @data.fetch('yt$firstName',{}).fetch('$t', "")
      last_name = @data.fetch('yt$lastName',{}).fetch('$t', "")
      [first_name, last_name].join(' ').strip
      end

      def get_data_from_youtube
        response = Faraday.get(@feed_url)
        return {} unless response.status == 200
        MultiJson.decode(response.body)['entry']
      end
    end
  end
end
