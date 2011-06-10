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
    def source
      read_attribute(:source).to_sym
    end

    def source= value
      write_attribute(:source, value.to_sym)
    end
    
    def serializable_hash options={}
      Hash["id" => id,
           "title" => title,
           "description" => description,
           "source" => source,
           "external_id" => external_id,
           "external_account_id" => external_account_id,
           "thumbnail_uri" => ""]
    end
    
  end
end
