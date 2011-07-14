require 'decay.rb'
module Aji
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

    # Future mentioner/tweeter/poster relationship.
    # has_many :posters, :through...

    # Symbolize source attribute.
    def source; read_attribute(:source).to_sym; end
    def source= value; write_attribute(:source, value.to_sym); end

    # TODO: Deprecate in favor of a generic `Video::fetch(source:Symbol,
    # external_id:String)`
    def self.find_or_create_from_youtubeit_video v
      external_account =
        ExternalAccounts::Youtube.find_or_create_by_uid(
          v.author.name, :provider => "youtube")
      Video.find_or_create_by_external_id(
        v.video_id.split(':').last,
        :title => v.title,
        :description => v.description,
        :external_account => external_account,
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
    
    def is_populated?; populated_at!=nil; end
    def populate
      raise "Aji::Video#populate: missing external id for Aji::Video[#{id}]" if external_id.nil?
      send "populate_from_#{source}"
      self.populated_at = Time.now
      save
    end
    def populate_from_youtube
      v = YouTubeIt::Client.new.video_by external_id # TODO: global YouTubeIt client
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
      time_diffs = []
      mentions.order("published_at DESC").limit(50).each do |mention|
        diff = at_time_i - mention.published_at.to_i
        next if diff < 0
        time_diffs << diff
      end
      Integer Aji::Decay.exponentially time_diffs
    end
    
    def serializable_hash options={}
      return Hash["id" => id, "external_id" => external_id, "source" => source.to_s ] if !is_populated?
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

  end
end
