module Aji
  # ## Event Schema
  # - id: Integer
  # - user_id: Integer (Foreign Key) non-nil
  # - video_id: Integer (Foreign Key) non-nil
  # - channel_id: Integer (Foreign Key) non-nil
  # - video_elapsed: Double
  # - event_type: Symbol as enum (String in db)
  # - created_at: DateTime
  # - updated_at: DateTime
  class Event < ActiveRecord::Base
    belongs_to :user
    belongs_to :video
    belongs_to :channel
    validates_inclusion_of :event_type,
      :in => [ :view, :share, :upvote, :downvote ]

    def event_type
      read_attribute(:event_type).to_sym
    end
    def event_type= value

      write_attribute(:event_type, value.to_s)
    end
  end
end
