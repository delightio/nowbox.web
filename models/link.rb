module Aji
  # The `Link` is a model that isn't backed by Postgres or Redis and
  # encapsulates all the properties of a hyperlink.
  # NOTE: I might back it by a Redis hash, or even the database. I haven't
  # decided yet I just want a fucking Link object.
  class Link < String
      @@youtube_id = %r<([-_\w]{11})>
      @@youtube_regexps = [
      @@youtube_url_1 = %r<https?://(?:www\.)?youtube(?:-nocookie)?\.com/v/#{@@youtube_id}["?]?>,
      @@youtube_url_2 = %r<https?://(?:www\.)?youtube(?:-nocookie)?\.com/watch\?(?:\S&)?v=#{@@youtube_id}[&"]?>,
      @@youtube_url_3 = %r<https?://(?:youtu|y2u)\.be/#{@@youtube_id}>]
      @@vimeo_url = %r<https?://(?:www\.)?vimeo\.com/(\d+)>

    def is_youtube_video?
      # Check if string matches any youtube urls and memoize the result.
      # TODO: Make link string of Link objects immutable.
      @youtube_match ||= @@youtube_regexps.map do |r|
        self =~ r ? true : false
      end.inject { |acc, el| acc ||= el }
    end

    def is_vimeo_video?
      @vimeo_match ||= self =~ @@vimeo_url ? true : false
    end

    # TODO: Implement this. (No shit sherlock)
    def is_shortened?
      false
    end
  end
end
