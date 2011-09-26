module Aji
  class Channel::User < Channel

    def searchable?; false; end

    def thumbnail_uri # LH 220
      case title
      when "Watch Later"
        "http://#{Aji.conf['TLD']}/images/icons/watch_later.png"
      when "Favorites"
        "http://#{Aji.conf['TLD']}/images/icons/favorites.png"
      when "History"
        "http://#{Aji.conf['TLD']}/images/icons/history.png"
      end
    end

    def refresh_content force=false
      # This is a no-op. All actions on this channel are done via its user.
    end
  end
end
