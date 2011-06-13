module Aji
  # ## Video Schema
  # - id: Integer
  # - account_id: Integer (Foreign Key)
  # - external_id: String
  # - source: String
  # - title: String
  # - description: Text
  # - viewable_mobile: Boolean
  # - created_at: DateTime
  # - updated_at: DateTime
  class Video < ActiveRecord::Base
    has_many :events
    belongs_to :external_account, :class_name => 'ExternalAccounts::Youtube'

    # Symbolize source attribute.
    def source; read_attribute(:source).to_sym; end
    def source= value; write_attribute(:source, value.to_sym); end
    
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
           "source" => source,
           "external_id" => external_id,
           "author" => author_hash,
           "thumbnail_uri" => thumbnail_uri]
    end
    
  end
end
