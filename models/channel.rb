module Aji
  # This is an interface class. Only actions and fields common to all Channel
  # types are included here. Required methods are defined and documented here
  # and raise an exception until overriden in a subclass.

  # ## Channel Schema
  # - id: Integer
  # - title: String
  # - type: String (ActiveRecord Column: ACCESS ONLY, DO NOT CHANGE)
  # - content_zset: Redis::Objects::SortedSet
  # - created_at: DateTime
  # - updated_at: DateTime
  class Channel < ActiveRecord::Base
    has_many :events

    include Redis::Objects
    sorted_set :content_zset

    def content_video_ids limit=-1
      content_zset.revrange 0, limit
    end

    def content_videos limit=-1
      content_video_ids.map { |vid| Video.find vid }
    end

    # The populate interface method is called by background tasks to fill the
    # channel with videos based on the specific channel type.
    def populate
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Channel#populate.")
    end

    def serializable_hash options={}
      thumbnail_uri = ""
      thumbnail_uri = Video.find(content_video_ids(1).first).thumbnail_uri if content_video_ids.count > 0
      Hash["id" => id,
           "type" => (type||"").split("::").last,
           "title" => title,
           "thumbnail_uri" => thumbnail_uri,
           "resource_uri" => "#{BASE_URL}/channels/#{self.id}"]
    end

    def personalized_content_videos args
      user = args[:user]
      raise ArgumentError, "User missing for Channel[#{self.id}].personalized #{args.inspect}" if user.nil?
      # TODO: just take out viewed videos
      limit = args[:limit] || 20
      new_video_ids = []
      # TODO: use Redis for this..
      viewed_video_ids = Set.new user.viewed_zset.range(0,-1)
      content_video_ids.each do |channel_video_id|
        new_video_ids << channel_video_id if !viewed_video_ids.member? channel_video_id
        break if new_video_ids.count >= limit
      end
      # new_video_ids = content_zset - user.viewed_zset # TODO: zdiff not found?
      new_video_ids.map { |vid| Video.find vid }
    end

  end
end
