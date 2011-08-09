module Aji
  # ## Category Schema
  # - id: Integer
  # - title: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class Category < ActiveRecord::Base
    def channel_ids; Channel.all.sample(1+rand(10)).map(&:id); end
    def serializable_hash options={}
      {
        "id" => 1+rand(10),
        "title" => self.class.random_string_,
        "channel_ids" => channel_ids
      }
    end
    
    def self.random_string_ length = 10
      letters = ('a'..'z').to_a
      (0...length).map { letters[rand 26] }.join
    end
  end
end