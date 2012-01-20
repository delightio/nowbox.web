module Aji
  module Mixins
    module Populating
      # Require a 'populated_at' DateTime database column

      def populated?
        !populated_at.nil?
      end

      def recently_populated?
        populated? && (populated_at > 6.hours.ago)
      end
    end
  end
end
