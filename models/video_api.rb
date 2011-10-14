module Aji
  class VideoAPI
    Error = Class.new StandardError

    def initialize sources=VideoAPI.source_apis.keys
      @apis = sources.map{ |s| VideoAPI.source_apis[s] }
    end

    def method_missing symbol, *args, &block
      @apis.map{ |api| api.send(symbol, *args, &block) }.flatten
    end

    def self.source_apis
      @@source_apis ||= {
        :youtube => YoutubeAPI,
        #:vimeo => VimeoAPI
      }.freeze
    end
  end
end
