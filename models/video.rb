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
    SOURCES = [:youtube]

    include Redis::Objects
    include Mixins::Blacklisting
    include Mixins::Populating

    counter :failures

    validates_presence_of :external_id, :source
    validates_inclusion_of :source, :in => SOURCES
    validates_uniqueness_of :external_id, :scope => :source
    validates_presence_of :author, :if => :populated?

    has_many :events
    has_and_belongs_to_many :mentions
    belongs_to :author, :class_name => 'Aji::Account'
    belongs_to :category, :class_name => 'Aji::Category'

    def populate
      unless populated?
        updated_info = api.video_info external_id
        self.author = updated_info.fetch :author
        self.category = updated_info.fetch :category
        updated_info.each do |attribute, value|
          self[attribute] = value if self.has_attribute? attribute
        end
        self.populated_at = Time.now
      end
    rescue Aji::VideoAPI::Error
      failed
      blacklist if failures.value >= MAX_FAILED_ATTEMPTS
    else
      populated_at = Time.now
      save and if block_given? then yield self else true end
    end

    # Symbolize source attribute.
    def source
      read_attribute(:source).to_sym
    end

    def source= value
      write_attribute(:source, value.to_sym)
    end

    def mark_spam
      Aji.redis.sadd "spammy_videos", id
      blacklist
      author.blacklist unless author.nil?
    end

    def thumbnail_uri
      case source
      when :youtube then "http://img.youtube.com/vi/#{self.external_id}/0.jpg"
      else ""
      end
    end

    def share_link
      "http://#{Aji.conf['TLD']}/videos/#{id}"
    end

    # Since Video#relevance is usually used when calculating a large collection
    # of videos, we request the input parameter to be an integer to save
    # unnecessary .to_i conversion on the time object
    def relevance at_time_i=Time.now.to_i
      return 0 if blacklisted?
      time_diffs = []
      mentions.latest(50).each do |mention|
        time_diffs << mention.age(at_time_i)
      end
      Integer Decay.exponentially time_diffs
    end

    def source_link
      case source
      when :youtube then "http://youtu.be/#{external_id}"
      when :vimeo then "http://vimeo.com/#{external_id}"
      else ""
      end
    end

    def serializable_hash options={}
      if populated?
        {
          "id" => id,
          "title" => title,
          "description" => description,
          "thumbnail_uri" => thumbnail_uri,
          "category" => category.serializable_hash,
          "source" => source.to_s,
          "external_id" => external_id,
          "duration" => duration.to_f,
          "view_count" => view_count,
          "published_at" => published_at.to_i,
          "author" => author.serializable_hash
        }
      else
        { "id" => id, "external_id" => external_id, "source" => source.to_s }
      end
    end

    def self.update_or_create_by_external_id_and_source(external_id, source, h)
      existing_or_new = find_or_create_by_external_id_and_source(external_id, source, h)
      existing_or_new.update_attributes h unless existing_or_new.populated?
      existing_or_new
    end

    def set_top_trending_in_category
      category.set_top_video_in_trending self
    end

    private
    MAX_FAILED_ATTEMPTS = 10

    def failed
      failures.increment
    end

    def api
      @api ||= VideoAPI.for_source(source)
    end
  end
end
