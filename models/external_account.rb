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

    def is_blacklisted?; Aji.redis.sismember ExternalAccount.blacklisted_ids_key, self.id; end
    def self.blacklist_id id; Aji.redis.sadd self.blacklisted_ids_key, id; end
    def self.blacklisted_ids; (Aji.redis.smembers self.blacklisted_ids_key).map(&:to_i); end
    def self.blacklisted_ids_key; "#{self.to_s}.blacklisted_ids"; end

    # The publish interface is called by background tasks to publish a video
    # share to an external service.
    def publish share
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

    def is_user?
      user_id ? true : false
    end
  end
end
