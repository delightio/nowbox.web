module Aji
  module Mixins
    module Populating
      
      # Require a 'populated_at' DateTime database column
      
      def populate
        raise InterfaceMethodNotImplemented
      end
      
      def populated?
        !populated_at.nil?
      end
      
      def recently_populated?
        populated? && (populated_at > 15.minutes.ago)
      end
      
    end
  end
end