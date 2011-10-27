module Aji
  class Channel::Fixed < Channel

    def refresh_content force=false
      # This is a no-op. All actions on this channel are done via its user.
    end

  end
end
