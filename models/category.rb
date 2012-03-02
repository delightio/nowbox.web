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
    list :onboard_channel_ids

    has_many :videos

    after_create :set_title
    after_destroy :delete_redis_keys

    def channel_ids limit=0
      (channel_id_zset.revrange 0, (limit-1)).map(&:to_i)
    end

    def channels limit=0
      channel_ids(limit).map { |cid| Channel.find_by_id cid }.compact
    end

    def update_channel_relevance channel, relevance
      channel_id_zset[channel.id] = relevance
    end

    def thumbnail_uri
      expected_path = "images/icons/categories/#{title.downcase}.png"
      if File.exists? "lib/viewer/public/#{expected_path}"
        return  "http://#{Aji.conf['TLD']}/#{expected_path}"
      end
      "http://#{Aji.conf['TLD']}/images/icons/cateogries/film.png"
    end

    def serializable_hash options={}
      {
        "id" => id,
        "title" => title,
        "thumbnail_uri" => thumbnail_uri
      }
    end

    def onboard_channels
      ids = onboard_channel_ids.values
      channels = ids.map { |cid| Channel.find_by_id cid }.compact.sample(2)
      channels = featured_channels(2) if channels.empty?
      channels
    end

    # Only returns channels which their top categories are also self.
    def featured_channels n=20
      results = []
      channels(n).each do |channel|
        if channel &&
           channel.available? &&
           channel.youtube_channel? &&
           channel.category_ids.first(2).include?(self.id)
          results << channel
        end
      end
      results
    end

    def redis_keys
      [ channel_id_zset, onboard_channel_ids ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Redis::Objects.redis.del key
      end
    end

    def set_title
      update_attribute(:title, raw_title) if title.nil?
    end

    def trending
      @trending ||= Channel::Trending.find_or_create_by_title "Now#{title}"
    end

    def self.undefined
      self.find_or_create_by_raw_title "*** undefined ***"
    end
  end
end
