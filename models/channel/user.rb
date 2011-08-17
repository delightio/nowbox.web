module Aji
  class Channel::User < Channel
    def thumbnail_uri # LH 220
      "http://beta.#{Aji.conf['TLD']}/images/icons/icon-set_nowtrending.png"
    end

    def refresh_content force=false
      # This is a no-op. All actions on this channel are done via its user.
    end
  end
end
