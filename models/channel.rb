module Aji
  # This is an interface class. Only actions and fields common to all Channel
  # types are included here. Required methods are defined and documented here
  # and raise an exception until overriden in a subclass.

  # ## Channel Schema
  # - id: Integer
  # - title: String
  # - type: String (ActiveRecord Column: ACCESS ONLY, DO NOT CHANGE)
  # - default_listing: Boolean
  # - content_zset: Redis::Objects::SortedSet
  # - created_at: DateTime
  # - updated_at: DateTime
  class Channel < ActiveRecord::Base
    include Redis::Objects
    include Mixins::ContentVideos
    include Mixins::CanRefreshContent
    include Mixins::Populating
    sorted_set :category_id_zset
    include Mixins::Featuring

    has_many :events, :class_name => 'Aji::Event'

    after_destroy :delete_redis_keys

    def category_ids limit=-1
      (category_id_zset.revrange 0, limit).map(&:to_i)
    end
    def categories limit=-1
      category_ids(limit).map { |cid| Category.find cid }
    end

    def thumbnail_uri
      ""
    end

    def description
      ""
    end

    def serializable_hash options={}
      h = {
        "id" => id,
        "type" => (type||"").split("::").last,
        "default_listing" => default_listing,
        # "category_ids" => category_ids, # iOS doesn't need them
        "title" => title,
        "description" => "",
        "thumbnail_uri" => thumbnail_uri,
        "subscriber_count" => subscriber_count,
        "video_count" => content_video_id_count,
        "populated_at" => populated_at.to_i,
        # TODO: Shouldn't just catch the first version since we may change
        # this method in a version bump.
        "resource_uri" => "http://api.#{Aji.conf['TLD']}/" +
          "#{Aji::API.version.first}/channels/#{self.id}"
      }
      if options && options[:inline_videos].to_i > 0
        h.merge!(
          "videos" => content_videos(options[:inline_videos]).
                        map{ |v| {"video" => v.serializable_hash(options)}}
        )
      end
      h
    end

    def subscriber_count
      0
    end

    def available?
      true
    end

    # TODO: Refactor to take a list of video ids and a limit parameter instead
    # of hash. This will reduce coupling and allow us to do more sophisticated
    # things than just removing a users viewed videos with less coupling and
    # thus less code.
    def personalized_content_videos args
      user = args[:user]
      raise ArgumentError, "User missing for Channel[#{self.id}].personalized" +
        " #{args.inspect}" if user.nil?
      limit = (args[:limit] || 20).to_i
      page = (args[:page] || 1).to_i
      total = limit * page
      new_videos = []
      if self.class == Channel::User
        # Always returns user channels in ascending order and
        # ignores blacklisted or viewed
        content_video_ids_rev.each do |channel_video_id|
          video = Video.find_by_id channel_video_id
          new_videos << video unless video.nil?
          break if new_videos.count >= total
        end
      elsif self.class == Channel::Fixed
        # Don't care if the videos are blacklisted or viewed
        new_videos = content_videos_rev(total)
      else
        # TODO: use Redis for this.. zdiff not found?
        viewed_video_ids = user.history_channel.content_video_ids
        content_video_ids.each do |channel_video_id|
          video = Video.find_by_id channel_video_id
          next if video.nil? || video.blacklisted?
          new_videos << video if !viewed_video_ids.member? channel_video_id
          break if new_videos.count >= total
        end
      end
      # iOS nsindexset can't handle video ID bigger than 4194303
      # new_videos[(total-limit)...total].to_a
      new_videos.select{|v| v.id < 4194303 }[(total-limit)...total].to_a
    end

    def background_refresh_content time = nil
      if time.nil?
        Resque.enqueue Queues::RefreshChannel, id
      else
        Resque.enqueue_in time, Queues::RefreshChannel, id
      end
    end

    def youtube_channel?
      self.class == Channel::Account and
        accounts.map(&:class) == [Aji::Account::Youtube]
    end

    def youtube_id
      if youtube_channel?
        accounts.first.uid
      end
    end

    def redis_keys
      [ content_zset, category_id_zset ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Redis::Objects.redis.del key
      end
    end

    def self.default_listing
      find_all_by_default_listing true
    end

    def self.trending
      Channel::Trending.singleton
    end

    def self.refreshable_types
      [ Channel::Account, Channel::Keyword, Channel::FacebookStream,
        Channel::TwitterStream ]
    end
  end
end

