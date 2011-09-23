module Aji
  module VideoAPI
    Error = Class.new StandardError

    def self.new source
      source_apis[source].new
    end

    def self.source_apis
      {
        :youtube => YoutubeAPI,
        #:vimeo => VimeoAPI
      }
    end
  end
end
