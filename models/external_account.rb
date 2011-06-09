module Aji
  # ## ExternalAccount Schema
  # - id: Integer
  # - user_info: Text (Serialized Hash)
  # - provider: String non-nil
  # - uid: String non-nil
  # - created_at: DateTime
  # - updated_at: DateTime
  class ExternalAccount < ActiveRecord::Base
    include Redis::Objects
    serialize :user_info
    serialize :credentials

    validates_presence_of :provider, :uid
  end
end
