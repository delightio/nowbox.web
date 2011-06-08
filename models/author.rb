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
    validates_presence_of :video_source
    validates_inclusion_of :video_source, :in => [ :youtube ]

    has_and_belongs_to_many :authors_channels,
      :class_name => 'Channels::AuthorsChannel'

    def video_source
      s = read_attribute(:video_source)
      s.to_sym if s
    end

    def video_source= value
      write_attribute(:video_source, value && value.to_s || nil)
    end
  end
end
