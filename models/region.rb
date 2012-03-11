module Aji
  class Region < ActiveRecord::Base
    include Redis::Objects
    after_destroy :delete_redis_keys
    has_many :users

    def redis_keys
      [ featured_channel_id_zset ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Aji.redis.del key
      end
    end

    # CHANNELS ################################################################
    sorted_set :featured_channel_id_zset

    def featured_channel_ids
      (master.featured_channel_id_zset.range 0, -1).map(&:to_i)
    end

    def featured_channels
      master.featured_channel_ids.map { |cid| Channel.find_by_id cid }.compact
    end

    def feature_channel channel
      master.featured_channel_id_zset[channel.id] = Time.now.to_i
    end

    def remove_channel channel
      master.featured_channel_id_zset.delete channel.id
    end
    # CHANNELS ################################################################

    def master
      # Right now we determine the master region from locale's language
      # Later we could do so with time zone as well.
      language_based
    end

    def language_based
      iso_code = Language.new(language).iso_code
      iso_code = "en" if !self.class.respond_to? iso_code.to_sym
      self.class.send iso_code.to_sym
    end

    def self.undefined
      find_or_create_by_language_and_locale nil, nil
    end

    # MASTER based on laungage ################################################

    def self.en
      find_or_create_by_language_and_locale "en", nil
    end

    def self.ko
      find_or_create_by_language_and_locale "ko", nil
    end

  end
end
