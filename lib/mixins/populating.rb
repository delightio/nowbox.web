module Aji
  module Mixins
    module Populating
      # Require a 'populated_at' DateTime database column

      def populated?
        !populated_at.nil?
      end

      def recently_refreshed? since_when
        populated? && (populated_at > since_when)
      end

      def refresh_period; 2.hours; end
      def should_refresh?
        !(recently_refreshed? Time.now-refresh_period)
      end

    end
  end
end
