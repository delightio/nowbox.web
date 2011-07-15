module Aji
  # TODO: yeah, I don't like this `Supported` thing and actions are SOAPy. ew.
  class Supported
    def self.video_actions; [:examine]; end
  end

  # ## Video Schema
  # - id: Integer
  # - account_id: Integer (Foreign Key)
  # - external_id: String
  # - source: String
  # - title: String
  # - description: Text
  # - viewable_mobile: Boolean
  # - duration: Double
  # - view_count: Integer
  # - published_at: DateTime
  # - created_at: DateTime
  # - updated_at: DateTime
  # - populated_at: DateTime
  class Video < ActiveRecord::Base
    has_many :events
    belongs_to :external_account
    has_and_belongs_to_many :mentions

    def is_blacklisted?; Aji.redis.sismember Video.blacklisted_ids_key, self.id; end
    def self.blacklist_id id; Aji.redis.sadd self.blacklisted_ids_key, id; end
    def self.blacklisted_ids; (Aji.redis.smembers self.blacklisted_ids_key).map(&:to_i); end
    def self.blacklisted_ids_key; "#{self.to_s}.blacklisted_ids"; end

    # Future mentioner/tweeter/poster relationship.
    # has_many :posters, :through...

    def thumbnail_uri
      # Case is an expression and will return the value previously set to
      # path.
      case source
      when :youtube then "http://img.youtube.com/vi/#{self.external_id}/0.jpg"
      else ""
      end
    end

    def is_populated?; not populated_at.nil?; end

    # Since Video#relevance is usually used when calculating a large collection
    # of videos, we request the input parameter to be an integer to save
    # unnecessary .to_i conversion on the time object
    def relevance at_time_i=Time.now.to_i
      return 0 if is_blacklisted?
      time_diffs = []
      mentions.order("published_at DESC").limit(50).each do |mention|
        diff = at_time_i - mention.published_at.to_i
        next if diff < 0 || mention.author.is_blacklisted?
        time_diffs << diff
      end
      Integer Decay.exponentially time_diffs
    end

    def serializable_hash options={}
      # unless is more idiomatic than `if !`
      return Hash["id" => id, "external_id" => external_id, "source" => source.to_s ] unless is_populated?
      author = external_account # TODO: 1. assume only 1 EA per video and 2. overloading EA#id
      author_hash = {}
      author_hash["username"] = author.username
      author_hash["profile_uri"] = author.profile_uri
      author_hash["external_account_id"] = author.id
      Hash["id" => id,
           "title" => title,
           "description" => description,
           "thumbnail_uri" => thumbnail_uri,
           "source" => source.to_s,
           "external_id" => external_id,
           "duration" => duration.to_f,
           "view_count" => view_count,
           "published_at" => published_at.to_i,
           "author" => author_hash]
    end

    # ## The Future Home of All Class Methods
    def Video.sources; [ :youtube, :vimeo ]; end
  end
end
