module Aji
  # Mention Schema
  # - id: Integer
  # - author_id: Integer (Foreign Key: ExternalAccount)
  # - body: Text
  # - external_id: Integer?
  # - unparsed_data: Text
  # - published_at: DateTime
  class Mention < ActiveRecord::Base
    belongs_to :author, :class_name => 'ExternalAccount'
    has_and_belongs_to_many :videos

  end
end
