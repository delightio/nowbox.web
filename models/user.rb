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
    sorted_set :subscribed_zset # User's Subscribed channels.
    
    def cache_event event
      at_time = event.created_at.to_i
      video_id = event.video_id
      
      viewed_zset[video_id] = at_time
      case event.event_type
      when :share, :upvote
        liked_zset[video_id] = at_time
        shared_zset[video_id] = at_time if event.event_type==:shared
      when :downvote
        downvoted_zset[video_id] = at_time
      when :enqueue
        queued_zset[video_id] = at_time
      when :dequeue
        queued_zset.delete video_id
      end
    end

    %w(shared_zset liked_zset downvoted_zset viewed_zset queued_zset).each do |zset|
      action = zset.split('_').first
      define_method :"#{action}_videos" do
        Video.find(send(zset.to_sym).members)
      end
    end

    def subscribed_channels
      Channel.find(subscribed_zset.members)
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
