module Aji
  # ## Author Schema
  # - id: Integer
  # - screen_name: String
  # - videos: Redis::Objects::SortedSet
  # - video_source: Symbol as enum (String in DB)
  # - created_at: DateTime
  # - updated_at: DateTime
  class Author < ActiveRecord::Base
    include Redis::Objects
    sorted_set :videos
    # We are using video source as an enum type so we must constrain it to
    # known values or nil. The easiest way to to so is with this validation.
    validates_inclusion_of :video_source, :in => [ :youtube ]

    def video_source
      read_attribute(:video_source).to_sym
    end

    def video_source= value
      write_attribute(:video_source, value.to_s)
    end
  end
end
