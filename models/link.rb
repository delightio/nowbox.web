module Aji
  # The `Link` is a model that isn't backed by Postgres or Redis and
  # encapsulates all the properties of a hyperlink.
  # NOTE: I might back it by a Redis hash, or even the database. I haven't
  # decided yet I just want a fucking Link object.
  class Link < String
    attr_accessor :external_id, :type
    def initialize str
      super str
      match_videos
    end
    @youtube_id_regexp = %r<([-_\w]{11})>
    @vimeo_id_regexp = /\d+/
    @youtube_regexps = [
      %r<https?://(?:www\.)?youtube(?:-nocookie)?\.com/v/#{@youtube_id}["?]?>,
      %r<https?://(?:www\.)?youtube(?:-nocookie)?\.com/watch\?(?:\S&)?v=#{@youtube_id}[&"]?>,
      %r<https?://(?:youtu|y2u)\.be/#{@youtube_id}>
    ]
    @vimeo_regexp = %r<https?://(?:www\.)?vimeo\.com/(#{@vimeo_id_regexp})>


    private
    def match_videos
      youtube_match = @youtube_urls.map do |r|
        self.match r || false
      end.inject { |acc, el| acc ||= el }
      vimeo_match = self.match @vimeo_regexp
      if youtube_match
        @external_id = youtube_match[1]
        @type = 'youtube'
      else
        if vimeo_match
          @external_id = vimeo_match[1]
          @type = 'vimeo'
        end
      end
    end

    def video?
      (@external_id && @@type) ? true : false
    end

    # TODO: Implement this. (No shit sherlock)
    def shortened?
      false
    end
  end
end
