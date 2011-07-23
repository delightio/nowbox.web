module Aji
  module Mixins
    module Populating
      
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