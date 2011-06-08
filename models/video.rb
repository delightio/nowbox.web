module Aji
  # ## Video Schema
  # - id: Integer
  # - external_id: String
  # - source: String
  # - title: String
  # - description: String
  # - viewable_mobile: Boolean
  # - created_at: DateTime
  # - updated_at: DateTime
  class Video < ActiveRecord::Base
    has_many :events
  end
end
