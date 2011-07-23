module Aji
  module Mixins
    module Populating
      
      # Require a 'populated_at' DateTime database column
      #
      # We need to add the following BEFORE including this mixins because
      # Redis::Objects expect a database ID to generate a unique redis key
      #
      # ************************
      # include Redis::Objects
      # lock :populating, :expiration => 10.minutes
      # ************************
      
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