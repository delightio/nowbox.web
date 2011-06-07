module Aji
  # ## Channel Schema
  # - id: Integer
  # - title: String
  # - channel_type: String
  # - videos: Redis::Objects::SortedSet
  # - authors: Redis::Objects::Authors
  # - created_at: DateTime
  # - updated_at: DateTime
  class Channel < ActiveRecord::Base
    include Redis::Objects
    sorted_set :videos
    list :authors
  end
end
