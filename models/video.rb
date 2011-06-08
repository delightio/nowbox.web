module Aji
  # ## Video Schema
  # - id: Integer
  # - author_id: Integer (Foreign Key)
  # - external_id: String
  # - source: String
  # - title: String
  # - description: String
  # - viewable_mobile: Boolean
  # - created_at: DateTime
  # - updated_at: DateTime
  class Video < ActiveRecord::Base
    has_many :events
    belongs_to :author

    def self.find_or_create_from_hash h
      # TODO: need to check all fields
      Aji::Video.find_or_create_by_external_id h[:external_id]
    end
  end
end
