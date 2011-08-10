module Aji
  # ## Account Schema
  # - id: Integer
  # - user_info: Text (Serialized Hash)
  # - uid: String non-nil
  # - created_at: DateTime
  # - updated_at: DateTime
  # - blacklisted_at: DateTime
  class Account < ActiveRecord::Base
    include Redis::Objects
    serialize :user_info
    serialize :credentials
    belongs_to :identity

    validates_presence_of :uid
    validates_uniqueness_of :uid, :scope => :type

    sorted_set :content_zset
    include Mixins::ContentVideos
    lock :populating, :expiration => 10.minutes
    include Mixins::Populating
    include Mixins::Blacklisting

    # The publish interface is called by background tasks to publish a video
    # share to an external service.
    def publish share
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Account#publish.")
    end

    def refresh_consumable_content
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Account#refresh_consumable_content.")
    end

    def refresh_generated_content
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Account#refresh_generated_content.")
    end

    def profile_uri; raise InterfaceMethodNotImplemented; end
    def thumbnail_uri; raise InterfaceMethodNotImplemented; end
    def refresh_content; raise InterfaceMethodNotImplemented; end
    def serializable_hash
      Hash[ "id" => id,
            "provider" => type.split('::').last.downcase,
            "uid" => uid,

            "username" => username,
            "profile_uri" => profile_uri,
            "thumbnail_uri" => thumbnail_uri ]
    end

  end
end
