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
    after_destroy :delete_redis_keys

    has_many :events

    include Redis::Objects
    include Mixins::ContentVideos
    include Mixins::CanRefreshContent
    include Mixins::Populating
    sorted_set :category_id_zset
    include Mixins::Featuring

    def category_ids limit=-1
      (category_id_zset.revrange 0, limit).map(&:to_i)
    end
    def categories limit=-1
      category_ids(limit).map { |cid| Category.find cid }
    end

    def thumbnail_uri; raise InterfaceMethodNotImplemented; end

    def serializable_hash options={}
      h = {
        "id" => id,
        "type" => (type||"").split("::").last,
        "default_listing" => default_listing,
        "category_ids" => category_ids,
        "title" => title,
        "description" => "",
        "thumbnail_uri" => thumbnail_uri,
        "video_count" => content_video_id_count,
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
      else
        # TODO: use Redis for this.. zdiff not found?
        viewed_video_ids = user.history_channel.content_video_ids
        content_video_ids.each do |channel_video_id|
          video = Video.find_by_id channel_video_id
          next if video.blacklisted?
          new_videos << video if !viewed_video_ids.member? channel_video_id
          break if new_videos.count >= total
        end
      end
      new_videos[(total-limit)...total].to_a
    end

    def update_relevance_in_categories new_videos
      new_videos.map(&:category_id).group_by{|g| g}.each do |h|
        cid = h.first; count = h.last.count # category_id => array of occurance
        category = Category.find cid
        category.update_channel_relevance self, count
        category_id_zset[cid] += count
      end
    end

    def background_refresh_content
      Resque.enqueue Queues::RefreshChannel, id
    end

    def redis_keys
      [ content_zset, category_id_zset ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Redis::Objects.redis.del key
      end
    end

    # ## Class Methods
    def self.search query
      results = []
      self.descendants.each do | descendant |
        next if descendant.searchable_columns.empty?
        results += descendant.send :search_helper, query
      end
      results.uniq!
      results.each { |ch| Resque.enqueue Queues::RefreshChannel, ch.id }
      results
    end

    def self.searchable_columns
      []
    end

    def self.search_helper query
      sql_string = searchable_columns.map {|c| "lower(#{c}) LIKE ?" }.join(' OR ')
      results = []
      query.tokenize.each do | q |
        sql = [ sql_string ]
        searchable_columns.count.times { |n| sql << "%#{q}%"}
        results += self.where sql
      end
      results.uniq # since we search per each keyword
    end

    def self.default_listing
      find_all_by_default_listing true
    end

    def self.trending
      Channel::Trending.singleton
    end

  end

end
