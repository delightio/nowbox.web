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
  class Video < ActiveRecord::Base
    has_many :events
    belongs_to :external_account

    # Future mentioner/tweeter/poster relationship.
    # has_many :posters, :through...

    # Symbolize source attribute.
    def source; read_attribute(:source).to_sym; end
    def source= value; write_attribute(:source, value.to_sym); end
    
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
        :published_at => v.published_at)
    end
    
    def thumbnail_uri
      path = case source
             when :youtube then "http://img.youtube.com/vi/#{self.external_id}/0.jpg"
             else ""
             end
      path
    end

    def serializable_hash options={}
      author = external_account # TODO: 1. asusme only 1 EA per video and 2. overloading EA#id
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
           "duration" => duration,
           "view_count" => view_count,
           "published_at" => published_at.to_i,
           "author" => author_hash]
    end

  end
end
