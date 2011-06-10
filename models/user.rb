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
    list :subscribed_list # User's Subscribed channels.
    
    def self.supported_channel_actions; [:subscribe, :unsubscribe, :arrange]; end
    def subscribe channel, args={}
      subscribed_list << channel.id
      subscribed_list.include? channel.id.to_s
    end
    def unsubscribe channel, args={}
      subscribed_list.delete channel.id
      !subscribed_list.include? channel.id.to_s
    end
    def arrange channel, args={}
      new_position = (args[:new_position] || args["new_position"]).to_i
      return false if new_position.nil? || !subscribed_list.include?(channel.id.to_s)
      return true if subscribed_list[new_position]==channel.id.to_s # below logic doesn't work for same pos
      subscribed_list.delete channel.id.to_s
      if subscribed_list.length <= new_position
        subscribed_list << channel.id
      else
        channel_id_at_new_position = subscribed_list[new_position]
        REDIS.linsert subscribed_list.key, "BEFORE", channel_id_at_new_position, channel.id
      end
      subscribed_list.include? channel.id.to_s
    end
    
    def cache_event event
      at_time = event.created_at.to_i
      video_id = event.video_id
      
      case event.event_type
      when :view
        viewed_zset[video_id] = at_time
        
      when :share
        viewed_zset[video_id] = at_time
        liked_zset[video_id] = at_time
        shared_zset[video_id] = at_time
        
      when :upvote
        viewed_zset[video_id] = at_time
        liked_zset[video_id] = at_time
        
      when :downvote
        viewed_zset[video_id] = at_time
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
      # Channel.find(subscribed_list.values) # TODO: Is AR caching this query? My list came out the same after User#arrange
      subscribed_list.map { |cid| Channel.find cid }
    end
  end
end
