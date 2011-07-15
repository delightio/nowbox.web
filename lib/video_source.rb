module Aji
  class VideoSource
    @source = nil

    # Generic search interface for all video sources.
    # Returns: an array of filled video objects.
    def search keywords
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must implement #search(keywords:Array[String])")
    end

    # Generic method to fetch a video from any source.
    # Returns: a single filled video object.
    def fetch source_id
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must implement #fetch(source_id:String)")
    end
  end
end
