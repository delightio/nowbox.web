require 'net/http'
require 'json'

module Aji
  class Channel::Trending < Channel
    include Redis::Objects

    def refresh_content force=true
    end

    def category
      title[3..-1]
    end

    def thumbnail_uri
      # Use category thumbnails
      "http://#{Aji.conf['TLD']}/images/icons/categories/#{category}.png"
    end

    def description
      "What #{category} videos the world is watching right now!"
    end

  end
end

