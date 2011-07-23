module Aji
  module Mixins
    module Blacklisting
      
      # Require a 'blacklisted_at' DateTime database column
      
      def blacklist
        self.blacklisted_at = Time.now
        save
      end
      
      def blacklisted?
        !blacklisted_at.nil?
      end
      
    end
  end
end