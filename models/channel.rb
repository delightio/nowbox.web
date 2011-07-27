module Aji
  class Supported
    def self.categories
      [ :undefined, :news, :sports, :music, :science, :comedy, :cars, :kids,
        :trailers, :gaming, :ted, :comedy, :film, :entertainment, :celebrity,
        :family]
    end
  end

  # This is an interface class. Only actions and fields common to all Channel
  # types are included here. Required methods are defined and documented here
  # and raise an exception until overriden in a subclass.

  # ## Channel Schema
  # - id: Integer
  # - title: String
  # - type: String (ActiveRecord Column: ACCESS ONLY, DO NOT CHANGE)
  # - default_listing: Boolean
  # - category: String
  # - content_zset: Redis::Objects::SortedSet
  # - created_at: DateTime
  # - updated_at: DateTime
  class Channel < ActiveRecord::Base
    has_many :events

    validates_inclusion_of :category, :in => Aji::Supported.categories
    def category; read_attribute(:category).to_s.to_sym; end
    def category= value; write_attribute(:category, value.to_s); end

    include Redis::Objects
    sorted_set :content_zset
    include Mixins::ContentVideos
    include Mixins::Populating

    def thumbnail_uri; raise InterfaceMethodNotImplemented; end

    def serializable_hash options={}
      {
        "id" => id,
        "type" => (type||"").split("::").last,
        "default_listing" => default_listing,
        "category" => category.to_s,
        "title" => title,
        "thumbnail_uri" => thumbnail_uri,
        # TODO: Shouldn't just catch the first version since we may change
        # this method in a version bump.
        "resource_uri" => "http://api.#{Aji.conf['TLD']}/" +
        "#{Aji::API.version.first}/channels/#{self.id}"
      }
    end

    def personalized_content_videos args
      user = args[:user]
      raise ArgumentError, "User missing for Channel[#{self.id}].personalized #{args.inspect}" if user.nil?
      # TODO: just take out viewed videos
      limit = (args[:limit] || 20).to_i
      new_videos = []
      # TODO: use Redis for this.. zdiff not found?
      viewed_video_ids = user.viewed_video_ids
      content_video_ids.each do |channel_video_id|
        video = Video.find_by_id channel_video_id
        next if video.blacklisted?
        new_videos << video if !viewed_video_ids.member? channel_video_id
        break if new_videos.count >= limit
      end
      new_videos
    end

    # ## Class Methods
    def self.default_listing
      find_all_by_default_listing true
    end

    def self.trending
      Channels::Trending.singleton
    end

  end

end
