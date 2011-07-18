module Aji
  class Supported
    def self.video_actions; [:examine]; end
  end

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
  class Video < ActiveRecord::Base
    has_many :events
    has_and_belongs_to_many :mentions
    belongs_to :author, :class_name => 'ExternalAccount'

    def blacklist; self.blacklisted_at = Time.now; save; end
    def blacklisted?; !blacklisted_at.nil?; end

    # Future mentioner/tweeter/poster relationship.
    # has_many :posters, :through...

    # Symbolize source attribute.
    def source; read_attribute(:source).to_sym; end
    def source= value; write_attribute(:source, value.to_sym); end
    
    def latest_mentions n=10
      mentions.order("published_at DESC").limit(n)
    end
    
    # TODO: Deprecate in favor of a generic `Video::fetch(source:Symbol,
    # external_id:String)`
    def self.find_or_create_from_youtubeit_video v
      author =
        ExternalAccounts::Youtube.find_or_create_by_uid(
          v.author.name, :provider => "youtube")
      Video.find_or_create_by_external_id(
        v.video_id.split(':').last,
        :title => v.title,
        :description => v.description,
        :author => author,
        :source => :youtube,
        :viewable_mobile => v.noembed,
        :duration => v.duration,
        :view_count => v.view_count,
        :published_at => v.published_at,
        :populated_at => Time.now)
    end

    def thumbnail_uri
      path = case source
             when :youtube then "http://img.youtube.com/vi/#{self.external_id}/0.jpg"
             else ""
             end
      path
    end

    def populated?; !populated_at.nil?; end

    def populate
      if external_id.nil?
        raise "Aji::Video#populate: missing external id for Aji::Video[#{id}]"
      end

      send "populate_from_#{source}"
      update_attribute :populated_at, Time.now
    end

    def populate_from_youtube
      v = YouTubeIt::Client.new.video_by external_id # TODO: global YouTubeIt client
      self.author = ExternalAccounts::Youtube.find_or_create_by_uid(
        v.author.name, :provider => "youtube")
      self.title = v.title
      self.description = v.description
      self.viewable_mobile = v.noembed
      self.duration = v.duration
      self.view_count = v.view_count
      self.published_at = v.published_at
    end

    # Since Video#relevance is usually used when calculating a large collection
    # of videos, we request the input parameter to be an integer to save
    # unnecessary .to_i conversion on the time object
    def relevance at_time_i=Time.now.to_i
      return 0 if blacklisted?
      time_diffs = []
      latest_mentions(50).each do |mention|
        diff = at_time_i - mention.published_at.to_i
        next if diff < 0 || mention.author.blacklisted?
        time_diffs << diff
      end
      Integer Decay.exponentially time_diffs
    end

    def serializable_hash options={}
      return Hash["id" => id, "external_id" => external_id, "source" => source.to_s ] if !populated?
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
  end
end
