module Aji
  # ## Video Schema
  # - id: Integer
  # - author_id: Integer (Foreign Key)
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
  # - category_id: Integer
  class Video < ActiveRecord::Base
    include Mixins::Blacklisting
    include Mixins::Populating

    validates_presence_of :external_id, :source
    validates_uniqueness_of :external_id, :scope => :source
    validates_presence_of :author, :if => :populated?

    has_many :events
    has_and_belongs_to_many :mentions
    belongs_to :author, :class_name => 'Account'
    belongs_to :category

    def populate
      if external_id.nil?
        raise "Aji::Video#populate: missing external id for Aji::Video[#{id}]"
      end

      send "populate_from_#{source}"
    rescue Macker::FetchError
      failed
      blacklist if failures >= MAX_FAILED_ATTEMPTS
    else
       self.populated_at = Time.now
       save && populated_at
    end

    # TODO: Merge this into Video#populate and use Macker for videos.
    def populate_from_youtube
      vhash = Macker.fetch :youtube, external_id
      vhash.each do |attribute, value|
        self[attribute] = value if self.has_attribute? attribute
      end
    end

    # Symbolize source attribute.
    def source
      read_attribute(:source).to_sym
    end

    def source= value
      write_attribute(:source, value.to_sym)
    end

    def latest_mentions n=50
      mentions.order("published_at DESC").limit(n)
    end
    def latest_mentioners limit=50
      latest_mentions(limit).map(&:author)
    end

    def mark_spam
      Aji.redis.sadd "spammy_videos", id
      blacklist
      author.blacklist unless author.nil?
    end

    def thumbnail_uri
      path = case source
             when :youtube then "http://img.youtube.com/vi/#{self.external_id}/0.jpg"
             else ""
             end
      path
    end

    # Since Video#relevance is usually used when calculating a large collection
    # of videos, we request the input parameter to be an integer to save
    # unnecessary .to_i conversion on the time object
    def relevance at_time_i=Time.now.to_i
      return 0 if blacklisted?
      time_diffs = []
      latest_mentions(50).each do |mention|
        time_diffs << mention.age(at_time_i)
      end
      Integer Decay.exponentially time_diffs
    end

    def serializable_hash options={}
      return Hash["id" => id, "external_id" => external_id, "source" => source.to_s ] if !populated?
      Hash["id" => id,
           "title" => title,
           "description" => description,
           "thumbnail_uri" => thumbnail_uri,
           "category" => category.serializable_hash,
           "source" => source.to_s,
           "external_id" => external_id,
           "duration" => duration.to_f,
           "view_count" => view_count,
           "published_at" => published_at.to_i,
           "author" => author.serializable_hash]
    end

    private
    MAX_FAILED_ATTEMPTS = 10

    def failures_key
      "video:#{id}:failures"
    end

    def failures
      Aji.redis.get(failures_key).to_i
    end

    def failed
      Aji.redis.set failures_key, failures+1
    end
  end
end
