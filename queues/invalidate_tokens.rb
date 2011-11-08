module Aji
  class Queues::InvalidateTokens
    @queue = :invalidate_tokens

    def self.perform
      Aji.redis.keys("authentication:*").each do |k|
        Aji.redis.del k
      end
    end
  end
end
