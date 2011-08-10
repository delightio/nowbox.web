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

    # def channel_ids; Channel.all.sample(1+rand(10)).map(&:id); end
    def serializable_hash options={}
      {
        "id" => id,
        "title" => title,
        "channel_ids" => channel_ids
      }
    end
  end
end

class String
  def self.random length = 10
    letters = ('a'..'z').to_a
    (0...length).map { letters[rand 26] }.join
  end
end