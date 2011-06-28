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
    belongs_to :user

    validates_presence_of :provider, :uid

    # The publish interface is called by background tasks to publish a video
    # share to an external service.
    def publish
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override ExternalAccount#publish.")
    end

    def serializable_hash
      {
        :id => id,
        :provider => provider,
        :uid => uid,
        :user_id => user_id
      }
    end
  end
end
