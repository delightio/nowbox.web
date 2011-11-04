module Aji
  class Token
    include OAuth::Helper

    def token_key
      "authentication:#{@token}"
    end

    class Generator < Token

      attr_reader :token, :expires_at
      def initialize user
        @user = user
        generate_token!
      end

      def generate_token!
        @token = generate_key
        store_token
      end

      def store_token
        Aji.redis.set token_key, @user.id
        @expires_at = 1.hour.from_now
        Aji.redis.expire token_key, 1.hour
      end
    end

    class Validator < Token
    end
  end
end
