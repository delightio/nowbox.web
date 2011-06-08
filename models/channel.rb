module Aji
  # This is an interface class. Only actions and fields common to all Channel
  # types are included here. Required methods are defined and documented here
  # and raise an exception until overriden in a subclass.

  # ## Channel Schema
  # - id: Integer
  # - title: String
  # - channel_type: String
  # - videos: Redis::Objects::SortedSet
  # - authors: Redis::Objects::Authors
  # - created_at: DateTime
  # - updated_at: DateTime
  class Channel < ActiveRecord::Base
    has_many :events

    include Redis::Objects
    sorted_set :content_zset
    list :authors

    def content_videos
      Video.find(content_zset.members)
    end

    # The populate interface method is called by background tasks to fill the
    # channel with videos based on the specific channel type.
    def populate
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Channel#perform.")
    end
  end
end
