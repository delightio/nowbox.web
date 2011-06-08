module Aji
  # ## User Schema
  # - id: Integer
  # - email: String
  # - created_at: DateTime
  # - updated_at: DateTime

  class User < ActiveRecord::Base
    has_many :events
    
    include Redis::Objects
    sorted_set :shared
    sorted_set :liked # upvoted or shared
    sorted_set :downvoted
    sorted_set :viewed
    sorted_set :queued
    
    def cache_event event
      at_time = event.created_at.to_i
      video_id = event.video_id

      viewed[video_id] = at_time
      case event.event_type
      when :share, :upvote
        liked[video_id] = at_time
        shared[video_id] = at_time if event.event_type==:shared
      when :downvote
        downvoted[video_id] = at_time
      when :enqueue
        queued[video_id] = at_time
      when :dequeue
        queued.delete video_id rescue false
      end
    end
    
  end
end
