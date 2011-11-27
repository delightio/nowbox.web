module Aji
  class APITracker
    LimitReached = Class.new Aji::Error

    attr_reader :cooldown, :hits_per_session, :redis, :namespace

    def initialize api_name, redis, options
      @namespace = api_name.strip.downcase.gsub(/[-\s]+/,'_')
      @redis = redis

      @hits_per_session = options.fetch :hits_per_session do
        raise ArgumentError, "Must supply :hits_per_session"
      end

      @cooldown = options.fetch :cooldown do
        raise ArgumentError, "Must supply :cooldown"
      end
    end

    def hit
      if available?
        hit!
        if block_given? then yield else true end
      else
        raise LimitReached,
          "Exceeded #{hits_per_session} #{namespace} hits before #{cooldown}"
      end
    end

    def available?
      hit_count < hits_per_session
    end

    def hit!
      unless redis.exists key
        redis.hset key, count_field, 0
        redis.expire key, cooldown
      end

      redis.hincrby key, count_field, 1
    end

    def seconds_until_available
      redis.ttl(key).to_i
    end

    def reset_session!
      redis.hset(key, count_field, 0)
      redis.expire(key, cooldown)
    end

    def hit_count
      redis.hget(key, count_field).to_i
    end

    def count_field
      'count'
    end

    def key
      "api_tracker:#{namespace}"
    end
  end
end
