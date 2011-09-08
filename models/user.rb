module Aji
  # ## User Schema
  # - id: Integer
  # - email: String
  # - first_name: String
  # - last_name: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class User < ActiveRecord::Base
    before_create :create_user_channels
    after_create :create_identity, :subscribe_featured_channels
    after_destroy :delete_redis_keys

    has_many :events
    belongs_to :identity
    belongs_to :queue_channel, :class_name => 'Channel::User'
    belongs_to :favorite_channel, :class_name => 'Channel::User'
    belongs_to :history_channel, :class_name => 'Channel::User'

    include Redis::Objects
    list :subscribed_list # User's Subscribed channels.

    def subscribe_featured_channels limit=4
      featured_channels = Channel.featured
      unless featured_channels.empty?
        featured_channels.first(limit).each { |c| subscribe c }
      end
      # TODO: we are pulling in the whole channel object but we really only care about Channel#id
    end

    def subscribed_channels
      # TODO: Is AR caching this query? My list came out the same after User#arrange
      # Channel.find(subscribed_list.values)
      subscribed_list.map { |cid| Channel.find cid }
    end

    def process_event event
      at_time = event.created_at.to_i
      video = event.video

      case event.action
      when :subscribe
        subscribe event.channel

      when :unsubscribe
        unsubscribe event.channel

      when :share
        favorite_channel.push video, event.created_at.to_i
        history_channel.push video, event.created_at.to_i
      when :unfavorite
        favorite_channel.pop video

      when :view, :examine
        history_channel.push video, event.created_at.to_i

      when :enqueue
        queue_channel.push video, event.created_at.to_i
      when :dequeue
        queue_channel.pop video

      end
    end

    def serializable_hash options={}
      hash = {
        "id" => id,
         "name" => name,
         "email" => email,
         "queue_channel_id" => queue_channel_id,
         "favorite_channel_id" => favorite_channel_id,
         "history_channel_id" => history_channel_id,
         "subscribed_channel_ids" => subscribed_list.values}
      unless identity.graph_channel.nil?
        hash.merge! "social_channel_id" => identity.graph_channel_id
      else
        hash
      end

    end

    def subscribed? channel
      subscribed_list.include? channel.id.to_s
    end
    def subscribe channel, args={}
      subscribed_list << channel.id if !subscribed? channel
      subscribed? channel
    end
    def unsubscribe channel, args={}
      subscribed_list.delete channel.id
      !subscribed?(channel)
    end

    def create_identity
      update_attribute :identity_id, Identity.create.id if self.identity.nil?
    end

    def redis_keys
      [ subscribed_list ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Aji.redis.del key
      end
    end

    def user_channels; [ queue_channel, favorite_channel ]; end
    def create_user_channels
      self.queue_channel = Channel::User.create :title => 'Watch Later'
      self.favorite_channel = Channel::User.create :title => 'Favorites'
      self.history_channel = Channel::User.create :title => 'History'
    end

    private :create_identity, :create_user_channels

  end
end

