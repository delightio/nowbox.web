module Aji
  # ## User Schema
  # - id: Integer
  # - email: String
  # - created_at: DateTime
  # - updated_at: DateTime

  class User < ActiveRecord::Base
    has_many :events

    include Redis::Objects
    sorted_set :shared_zset
    sorted_set :liked_zset # upvoted or shared
    sorted_set :downvoted_zset
    sorted_set :viewed_zset
    sorted_set :queued_zset

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
        queued.delete video_id
      end
    end

    %w(shared_zset liked_zset downvoted_zset viewed_zset queued_zset).
      map(&:to_sym).each do |sym|
      define_method :"#{sym}_videos" do
        Video.find(send(sym).members)
      end
    end

#    def shared_videos
#      shared.members.map { |id| Video.find(id) }
#    end
#
#    def liked_videos
#      liked.members.map { |id| Video.find(id) }
#    end
#
#    def downvoted_videos
#      downvoted.members.map { |id| Video.find(id) }
#    end
#
#    def viewed_videos
#      viewed.members.map { |id| Video.find(id) }
#    end
#
#    def queued_videos
#      queued.members.map { |id| Video.find(id) }
#    end
  end
end
