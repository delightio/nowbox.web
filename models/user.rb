module Aji
  # ## User Schema
  # - id: Integer
  # - email: String
  # - first_name: String
  # - last_name: String
  # - created_at: DateTime
  # - updated_at: DateTime
  class User < ActiveRecord::Base

    include Redis::Objects
    list :subscribed_list
    list :social_channel_list

    serialize :settings, Hash

    has_many :events
    belongs_to :identity
    belongs_to :region
    belongs_to :queue_channel, :class_name => 'Channel::User',
      :dependent => :destroy
    belongs_to :favorite_channel, :class_name => 'Channel::User',
      :dependent => :destroy
    belongs_to :history_channel, :class_name => 'Channel::User',
      :dependent => :destroy

    after_initialize :initialize_settings
    before_create :create_user_channels
    after_create :create_identity
    after_destroy :delete_redis_keys

    def self.create_from other
      user = User.create
      user.copy_from! other
      user
    end

    def subscribe_featured_channels
      if region.nil?
        Aji.log "User[#{id}] is not assigned to any region."
        return
      end

      region.featured_channels.each { |c| subscribe c }
    end

    def process_event event
      at_time = event.created_at.to_i
      video = event.video

      case event.action
      when :subscribe
        subscribe event.channel

      when :unsubscribe
        unsubscribe_from_all event.channel

      when :share
        watched_video event.video, event.created_at

      when :favorite
        watched_video event.video, event.created_at
        favorite_video event.video, event.created_at

      when :unfavorite
        unfavorite_video event.video

      when :view, :examine
        watched_video event.video, event.created_at

      when :enqueue
        enqueue_video event.video, event.created_at

      when :dequeue
        dequeue_video event.video
      end
    end

    def serializable_hash options={}
      {
        "id" => id,
        "name" => name,
        "email" => email,
        "queue_channel_id" => queue_channel_id,
        "favorite_channel_id" => favorite_channel_id,
        "history_channel_id" => history_channel_id,
        "twitter_channel_id" => twitter_channel_id,
        "facebook_channel_id" => facebook_channel_id,
        "subscribed_channel_ids" => subscribed_channel_ids,
        "accounts" => identity.account_info
      }
    end

    def subscribed_channels
      channels = subscribed_list.map{ |cid| Channel.find_by_id cid }.compact
      remove_missing_channels channels.map(&:id) if channels.length <
        subscribed_list.length

      channels
    end

    def social_channels
      channels = social_channel_list.map{ |cid| Channel.find_by_id cid }.compact
      remove_missing_channels channels.map(&:id) if channels.length <
        social_channel_list.length

      channels
    end

    def youtube_channels
      subscribed_channels.select &:youtube_channel?
    end

    def facebook_channel_id
      if c = social_channels.find{|c| c.class == Channel::FacebookStream }
        c.id
      else
        nil
      end
    end

    def twitter_channel_id
      if c = social_channels.find{|c| c.class == Channel::TwitterStream }
        c.id
      else
        nil
      end
    end

    def twitter_account
      if c = social_channels.find{|c| c.class == Channel::TwitterStream }
        c.owner
      else
        nil
      end
    end

    def enable_twitter_post
      settings[:post_to_twitter] = true
      save
    end

    def facebook_account
      if c = social_channels.find{|c| c.class == Channel::FacebookStream }
        c.owner
      else
        nil
      end
    end

    def enable_facebook_post
      settings[:post_to_facebook] = true
      save
    end

    def autopost_accounts
      [].tap do |accounts|
        accounts << twitter_account if settings[:post_to_twitter]
        accounts << facebook_account if settings[:post_to_facebook]
      end
    end

    def subscribed_channel_ids
      subscribed_list.values.map(&:to_i)
    end

    def subscribed? channel
      subscribed_list.include? channel.id.to_s
    end

    def subscribed_social? channel
      social_channel_list.include? channel.id.to_s
    end

    def subscribe channel
      subscribed_list << channel.id unless subscribed? channel
      identity.hook :subscribe, channel unless @no_hooks
      subscribed? channel
    end

    def subscribe_social channel
      social_channel_list << channel.id unless subscribed_social? channel
      subscribed_social? channel
    end

    def unsubscribe channel
      subscribed_list.delete channel.id
      identity.hook :unsubscribe, channel unless @no_hooks
      not subscribed? channel
    end

    def unsubscribe_social channel
      social_channel_list.delete channel.id
      not subscribed_social? channel
    end

    def unsubscribe_from_all channel
      [ unsubscribe(channel), unsubscribe_social(channel) ].all?
    end

    def watched_video video, watched_time
      history_channel.push video, watched_time.to_i
    end

    def favorite_video video, favorited_time
      favorite_channel.push video, favorited_time.to_i
      identity.hook :favorite, video unless @no_hooks
    end

    def unfavorite_video video
      favorite_channel.pop video
      identity.hook :unfavorite, video unless @no_hooks
    end

    def enqueue_video video, enqueued_time
      queue_channel.push video, enqueued_time.to_i
      identity.hook :enqueue, video unless @no_hooks
    end

    def dequeue_video video
      queue_channel.pop video
      identity.hook :dequeue, video unless @no_hooks
    end

    def without_hooks!
      @no_hooks = true
      yield
      @no_hooks = nil
    end

    def favorite_videos
      favorite_channel.content_videos
    end

    def queued_videos
      queue_channel.content_videos
    end

    def redis_keys
      [ subscribed_list ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Aji.redis.del key
      end
    end

    def user_channels
      [history_channel, queue_channel, favorite_channel]
    end

    def displayable_user_channels
      [queue_channel, favorite_channel]
    end

    def display_channels
      displayable_user_channels + social_channels + subscribed_channels
    end

    def first_name
      self.name.split(' ').first
    end

    def last_name
      self.name.split(' ').last
    end

    def copy_from! other
      merge! other
      other.social_channels.each do |c|
        subscribe_social c
      end
    end

    def merge! other
      other.subscribed_channels.each do |c|
        subscribe c
      end

      history_channel.merge! other.history_channel
      favorite_channel.merge! other.favorite_channel
      queue_channel.merge! other.queue_channel

      self.region = other.region
      self.settings = other.settings
      self.name = other.name if name == ""
      self.email = other.email if email == ""

      if other.updated_at.to_i > updated_at.to_i
        self.name = other.name unless other.name == ""
        self.email = other.email unless other.email == ""
      end
      # TODO: don't we need to do a save?
      save
    end

    private
    def create_user_channels
      self.queue_channel = Channel::User.create :title => 'Watch Later'
      self.favorite_channel = Channel::User.create :title => 'Favorites'
      self.history_channel = Channel::User.create :title => 'History'
    end

    def remove_missing_channels known_good_ids=[]
      [subscribed_list, social_channel_list].each do |channel_list|
        channel_list.map(&:to_i).each do |id|
          unless known_good_ids.include?(id) || Channel.find_by_id(id)
            channel_list.delete id
          end
        end
      end
    end

    def create_identity
      update_attribute :identity_id, Identity.create.id if self.identity.nil?
    end

    def initialize_settings
      self.settings ||= {}
    end
  end
end

