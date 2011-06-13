module Aji
  class Supported
    def self.event_types; [ :view, :share, :upvote, :downvote, :enqueue, :dequeue ]; end
  end
  
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
    after_create :cache_for_user
    
    validates_inclusion_of :event_type, :in => Aji::Supported.event_types
    def event_type; read_attribute(:event_type).to_sym; end
    def event_type= value; write_attribute(:event_type, value.to_s); end
    
    private
      def cache_for_user
        self.user.cache_event self
      end
  end
end
