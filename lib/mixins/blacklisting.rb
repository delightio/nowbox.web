module Aji
  module Mixins
    module Blacklisting

      # Require a 'blacklisted_at' DateTime database column

      def blacklist
        update_attribute(:blacklisted_at, Time.now) unless blacklisted?
      end

      def blacklisted?
        !blacklisted_at.nil?
      end
    end
  end
end

