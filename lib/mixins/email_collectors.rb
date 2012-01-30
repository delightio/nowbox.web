module Aji
  module Mixins::EmailCollectors
    module Facebook

      def email_collector_key
        "EmailCollectors::Facebook"
      end

      def collect_email
        Aji.redis.sadd(email_collector_key, email) unless email.nil?
      end

    end
  end
end