module Aji
  # ## User Schema
  # - id: Integer
  # - email: String
  # - first_name: String
  # - last_name: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class User < ActiveRecord::Base
    validates_presence_of :email, :first_name
    validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create
    after_create :create_identity, :subscribe_default_channels
    before_destroy :clean_redis_keys

    belongs_to :identity
    has_many :events

    include Redis::Objects
    sorted_set :shared_zset
    sorted_set :liked_zset # upvoted or shared
    sorted_set :viewed_zset
    sorted_set :queued_zset
    list :subscribed_list # User's Subscribed channels.

    def subscribe_default_channels
      Channel.default_listing.each { |c| subscribe c }
      # TODO: we are pulling in the whole channel object but we really only care about Channel#id
    end

    def subscribed_channels
      # TODO: Is AR caching this query? My list came out the same after User#arrange
      # Channel.find(subscribed_list.values)
      subscribed_list.map { |cid| Channel.find cid }
    end

    def process_event event
      at_time = event.created_at.to_i
      video_id = event.video_id

      case event.action
      when :subscribe
        subscribe event.channel

      when :unsubscribe
        unsubscribe event.channel

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

      when :examine
        viewed_zset[video_id] = at_time 

      end
    end

    %w(shared_zset liked_zset downvoted_zset viewed_zset queued_zset).each do |zset|
      action = zset.split('_').first

      # Define direct video accessor for all sets.
      define_method :"#{action}_videos" do
        Video.find(send(zset.to_sym).members)
      end

      # Define video id accessor for all sets.
      define_method :"#{action}_video_ids" do
        Set.new send(zset.to_sym).members.map(&:to_i)
      end
    end

    def serializable_hash options={}
      Hash["id" => id,
           "first_name" => first_name,
           "last_name" => last_name,
           "subscribed_channel_ids" => subscribed_list.values]
    end

    def subscribed? channel
      subscribed_list.include? channel.id.to_s
    end
    def subscribe channel, args={}
      subscribed_list << channel.id
      subscribed? channel
    end
    def unsubscribe channel, args={}
      subscribed_list.delete channel.id
      !subscribed?(channel)
    end

    def create_identity
      update_attribute :identity_id, Identity.create.id if self.identity.nil?
    end
    private :create_identity

    def clean_redis_keys
      [subscribed_list, shared_zset, liked_zset, queued_zset, viewed_zset
      ].map { |col| col.key }.each do |key|
        Aji.redis.del key
      end
    end
  end
end

