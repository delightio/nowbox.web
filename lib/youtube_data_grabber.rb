module Aji
  class YoutubeDataGrabber
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

    def get_data_from_youtube
      response = Faraday.get(@feed_url)
      return {} unless response.status == 200
      MultiJson.decode(response.body)['entry']
    end
  end
end
