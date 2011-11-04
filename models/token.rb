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
      def initialize token
        @token = token
      end

      def get_token_data
        Aji.redis.get(token_key)
      end

      def valid?
        not get_token_data.nil?
      end

      def valid_for? user
        get_token_data.to_i == user.id
      end
    end
  end
end
