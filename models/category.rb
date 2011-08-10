module Aji
  # ## Category Schema
  # - id: Integer
  # - title: String
  # - label: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class Category < ActiveRecord::Base
    after_create :set_title
    def set_title; update_attribute(:title, raw_title) if title.nil?; end
    
    def channel_ids; Channel.all.sample(1+rand(10)).map(&:id); end
    def serializable_hash options={}
      {
        "id" => 1+rand(10),
        "title" => ::String.random,
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