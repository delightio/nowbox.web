module Aji
  # Mention Schema
  # - id: Integer
  # - author_id: Integer (Foreign Key: ExternalAccount)
  # - body: Text
  # - external_id: Integer?
  # - unparsed_data: Text
  class Mention < ActiveRecord::Base
    belongs_to :author, :class_name => 'ExternalAccount'

  end
end
