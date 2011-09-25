module Aji
  # ## Category Schema
  # - id: Integer
  # - title: String
  # - raw_title: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class Category < ActiveRecord::Base
    include Redis::Objects
    include Mixins::Featuring

    sorted_set :channel_id_zset

    has_many :videos

    after_create :set_title
    after_destroy :delete_redis_keys

    def channel_ids limit=-1
      (channel_id_zset.revrange 0, limit).map(&:to_i)
    end

    def channels limit=-1
      channel_ids(limit).map { |cid| Channel.find_by_id cid }
    end
    def update_channel_relevance channel, relevance
      channel_id_zset[channel.id] += relevance
    end

    def serializable_hash options={}
      {
        "id" => id,
        "title" => title
      }
    end

    # Only returns channels which their top categories are also self.
    def featured_channels
      results = []
      channel_ids.first(10).each do |channel_id|
        channel = Channel.find_by_id channel_id
        if channel.category_ids.first(2).include? self.id
          results << channel
        end
      end
      results
    end

    def redis_keys
      [ channel_id_zset ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Redis::Objects.redis.del key
      end
    end

    def set_title
      update_attribute(:title, raw_title) if title.nil?
    end

    def self.undefined
      self.find_or_create_by_raw_title "*** undefined ***"
    end
  end
end
