module Aji
  # ## Channel Schema
  # - id: Integer
  # - title: String
  # - videos_key: String (Redis key)
  # - channel_type: String
  # - contributors_key: String (Redis key)
  # - created_at: DateTime
  # - updated_at: DateTime
  class Channel < ActiveRecord::Base
    include Redis::Objects
    sorted_set :videos
    list :contributors
  end
end
