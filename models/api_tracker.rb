module Aji
  class APITracker
    LimitReached = Class.new Aji::Error

    attr_reader :cooldown, :hits_per_session, :redis, :namespace, :method_limits

    # Mandatory options are `hits_per_session`, the number of of hits of any kind
    # allowable during a single session. And `cooldown`, the time in seconds
    # before a session expires.
    # Additional options are method limits. #hit, #hit!, and #available? all
    # take an optional method name. You can prioritize types of methods using
    # this feature. Create a hash specifiying the proportion 0 < x < 1 of the
    # total hits per session which can be taken up by this method. The sum total
    # of proportions need not equal 1. The feature merely limits the method to
    # at most that proportion of the full quota.
    def initialize api_name, redis, options
      @namespace = api_name.strip.downcase.gsub(/[-\s]+/,'_')
      @redis = redis

      @hits_per_session = options.fetch :hits_per_session do
        raise ArgumentError, "Must supply :hits_per_session"
      end

      @cooldown = options.fetch :cooldown do
        raise ArgumentError, "Must supply :cooldown"
      end

      # Process method limits as a proportion of total hits.
      # If no methods are limited, each has the complete quota available.
      @method_limits = Hash.new @hits_per_session
      if options[:method_limits]
        options[:method_limits].each do |method, proportion|
          @method_limits[method] = (@hits_per_session * proportion).floor
        end
      end
    end

    def hit api_method = nil
      if available? api_method
        hit! api_method
        if block_given? then yield else true end
      else
        close_session!("available? #{api_method} => false") unless throttled?
        raise LimitReached,
          "Exceeded #{hits_per_session} #{namespace} hits before #{cooldown}"
      end
    end

    def available? api_method = nil

      # Temp fix for why key still exists but there is no expiry time.
      unless seconds_until_available > 0
        redis.expire key, cooldown
      end

      return false if throttled?
      if api_method
        return false unless hit_count(api_method) < @method_limits[api_method]
      else
        return false unless hit_count < hits_per_session
      end

      true
    end

    def hit! api_method = nil
      unless redis.exists key
        redis.hset key, count_key, 0
        redis.expire key, cooldown
      end

      redis.hincrby key, api_method, 1 if api_method
      redis.hincrby key, count_key, 1
    end

    def seconds_until_available
      redis.ttl key
    end

    def reset_session!
      redis.del(key)
    end

    def hit_count api_method = nil
      if api_method
        redis.hget(key, api_method).to_i
      else
        redis.hget(key, count_key).to_i
      end
    end

    def throttled?
      redis.hexists(key, throttle_key)
    end

    def close_session! reason=""
      redis.hset key, throttle_key, "yes"
      redis.hset key, throttle_reason_key, reason
      redis.expire key, cooldown # reset expiry time

      redis.zadd throttle_count_key, Time.now.to_i, MultiJson.encode(to_json)
    end

    def add_missed_call info
      redis.zadd missed_calls_key, Time.now.to_i, info
    end

    def to_json
      h = redis.hgetall key
      h.merge "ttl" => seconds_until_available.to_s # consistent w/ hgetall
    end

    def count_key
      'count'
    end

    def throttle_key
      'throttled'
    end

    def throttle_reason_key
      'throttled_reason'
    end

    def throttle_count_key
      "#{key}:throttle_count"
    end

    def missed_calls_key
      "#{key}:missed_calls"
    end

    def key
      "api_tracker:#{namespace}"
    end
  end
end
