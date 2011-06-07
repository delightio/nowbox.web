module Aji
  # ## User Schema
  # - id: Integer
  # - email: String
  # - created_at: DateTime
  # - updated_at: DateTime

  class User < ActiveRecord::Base
    include Redis::Objects

    sorted_set :favorites
    sorted_set :disliked
    sorted_set :watched
    sorted_set :queueq

  end
end
