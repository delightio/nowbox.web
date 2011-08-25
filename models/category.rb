module Aji
  # ## Category Schema
  # - id: Integer
  # - title: String
  # - raw_title: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class Category < ActiveRecord::Base
    has_many :videos
    after_create :set_title
    def set_title; update_attribute(:title, raw_title) if title.nil?; end
    def self.undefined
      self.find_or_create_by_raw_title "*** undefined ***"
    end

    include Redis::Objects
    sorted_set :channel_id_zset
    def channel_ids limit=-1
      (channel_id_zset.revrange 0, limit).map(&:to_i)
    end
    def channels limit=-1
      channel_ids(limit).map { |cid| Channel.find cid }
    end
    def update_channel_relevance channel, relevance
      channel_id_zset[channel.id] += relevance
    end

    def serializable_hash options={}
      {
        "id" => id,
        "title" => title,
        "channel_ids" => channel_ids
      }
    end

    # Only returns channels which their top categories are also self.
    def featured_channels args={}
      results = []
      channel_ids.first(10).each do |channel_id|
        channel = Channel.find channel_id
        if channel.category_ids.first(2).include? self.id
          results << channel_id
        end
      end
      results
    end

    def self.featured_key; "Aji::Category::featured::ids"; end
    def self.featured args={}
      featured_ids = redis.lrange featured_key, 0, -1
      return self.find featured_ids unless featured_ids.empty?
      Category.all.sample(10) - [undefined]
    end

  end
end
