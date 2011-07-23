module Aji
  # ## ExternalAccount Schema
  # - id: Integer
  # - user_info: Text (Serialized Hash)
  # - uid: String non-nil
  # - created_at: DateTime
  # - updated_at: DateTime
  # - blacklisted_at: DateTime
  class ExternalAccount < ActiveRecord::Base
    include Redis::Objects
    serialize :user_info
    serialize :credentials
    belongs_to :user

    validates_presence_of :uid
    
    include Redis::Objects
    sorted_set :content_zset
    include Mixins::ContentVideos
    include Mixins::Blacklisting
    
    # The publish interface is called by background tasks to publish a video
    # share to an external service.
    def publish share
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override ExternalAccount#publish.")
    end

    def serializable_hash
      {
        :id => id,
        :provider => type.split('::').last.downcase,
        :uid => uid,
        :user_id => user_id
      }
    end
    
  end
end
