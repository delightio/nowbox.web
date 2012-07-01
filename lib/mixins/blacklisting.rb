module Aji
  module Mixins
    module Blacklisting

      # Require a 'blacklisted_at' DateTime database column

      def blacklist
        # Do not blacklist any video or account.
        # It will eventually blacklist everything and make Nowbox unusable.
        # update_attribute(:blacklisted_at, Time.now) unless blacklisted?
      end

      def blacklisted?
        !blacklisted_at.nil?
      end
    end
  end
end

