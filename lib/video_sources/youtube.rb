class Aji::VideoSources::Youtube

  def search keywords
    videos = []
    (1..3).each do |page|
      it_videos = VideoSources.youtube_client.
        videos_by(:query => keywords.join(' '), :page => page).videos
      it_videos.each do |v|
        videos << create_video(v)
      end
    end
    videos
  end

  def create_video youtube_it_video
    author = ExternalAccounts::Youtube.find_or_create_by_uid(
      youtube_it_video.author.name, :provider => "youtube")

      Video.find_or_create_by_external_id(
        youtube_it_video.video_id.split(':').last,
        :title => youtube_it_video.title,
        :description => youtube_it_video.description,
        :external_account => author,
        :source => :youtube,
        :viewable_mobile => youtube_it_video.noembed,
        :duration => youtube_it_video.duration,
        :view_count => youtube_it_video.view_count,
        :published_at => youtube_it_video.published_at,
        :populated_at => Time.now)
  end
end
