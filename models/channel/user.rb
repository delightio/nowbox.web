module Aji
  class Channel::User < Channel
    def thumbnail_uri # LH 220
      "http://beta.#{Aji.conf['TLD']}/images/icons/icon-set_nowtrending.png"
    end
  end
end
