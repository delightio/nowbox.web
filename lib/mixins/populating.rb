module Aji
  module Mixins
    module Populating
      # Require a 'populated_at' DateTime database column

      def populated?
        !populated_at.nil?
      end

      def self.refresh_period
        6.hours
      end

      def recently_populated?
        populated? && (populated_at > self.class.refresh_period.ago)
      end
    end
  end
end
