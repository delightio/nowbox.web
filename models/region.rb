module Aji
  class Region < ActiveRecord::Base
    include Redis::Objects
    sorted_set :featured_channel_id_zset

    def featured_channel_ids
      (featured_channel_id_zset.range 0, -1).map(&:to_i)
    end

    def featured_channels
      featured_channel_ids.map { |cid| Channel.find_by_id cid }.compact
    end

    def add_featured_channel channel
      featured_channel_id_zset[channel.id] = Time.now.to_i
    end

    def remove_featured_channel channel
      featured_channel_id_zset.delete channel.id
    end

    def self.undefined
      find_or_create_by_locale_and_time_zone nil, nil
    end

  end
end
