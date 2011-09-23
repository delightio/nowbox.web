module Aji
  class YoutubeAPI

    @@client ||= YouTubeIt::Client.new {}

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
  end
end
