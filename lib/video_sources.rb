Aji.autoload :VideoSource, './video_source'

module Aji::VideoSources
  def self.youtube_client
    @youtube_client ||= YouTubeIt::Client.new
  end

  def self.vimeo_client
    @vimeo_client ||= Vimeo::Simple.new
  end

  autoload :Youtube, './video_sources/youtube'
  autoload :Vimeo, './video_sources/vimeo'
end
