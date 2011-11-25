module Aji
  class Channel::Recommended < Channel

    def available?
      false
    end

    def thumbnail_uri # TODO: temp icon
      "http://#{Aji.conf['TLD']}/images/icons/nowpopular.png"
    end

    def refresh_content force=false
    end

  end
end

