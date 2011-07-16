module Aji
  class Supported
    def self.categories
      [ :undefined, :news, :sports, :music, :science, :comedy, :cars, :kids, :trailers, :gaming, :ted, :funny ]
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

    # TODO: This isn't a particularly robust interface. I'm writing my own Redis
    # object library so when that's finished we'll use it.
    def content_video_ids limit=-1
      (content_zset.revrange 0, limit).map(&:to_i)
    end
    def content_videos limit=-1
      content_video_ids(limit).map { |vid| Video.find vid }
    end
    def relevance_of video
      content_zset.score video.id
    end

    # Push a video into the channel's content.
    def push video, relevance=Time.now.to_i
      content_zset[video.id] = relevance
    end

    def serializable_hash options={}
      thumbnail_uri = ""
      thumbnail_uri = Video.find(content_video_ids(1).first).thumbnail_uri if content_video_ids.count > 0
      Hash["id" => id,
           "type" => (type||"").split("::").last,
           "default_listing" => default_listing,
           "category" => category.to_s,
           "title" => title,
           "thumbnail_uri" => thumbnail_uri,
           "resource_uri" => "http://api.#{Aji.conf['TLD']}/#{Aji::API.version.first}/channels/#{self.id}"]
    end

    # The populate interface method is called by background tasks to fill the
    # channel with videos based on the specific channel type.
    def populate
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Channel#populate.")
    end

    def personalized_content_videos args
      user = args[:user]
      raise ArgumentError, "User missing for Channel[#{self.id}].personalized #{args.inspect}" if user.nil?
      # TODO: just take out viewed videos
      limit = (args[:limit] || 20).to_i
      new_video_ids = []
      # TODO: use Redis for this..
      viewed_video_ids = user.viewed_video_ids
      content_video_ids.each do |channel_video_id|
        next if Video.blacklisted_ids.include? channel_video_id
        new_video_ids << channel_video_id if !viewed_video_ids.member? channel_video_id

        break if new_video_ids.count >= limit
      end
      # new_video_ids = content_zset - user.viewed_zset # TODO: zdiff not found?
      new_video_ids.map{ |vid| Video.find_by_id vid }.compact
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
