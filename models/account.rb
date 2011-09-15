module Aji
  # ## Account Schema
  # - id: Integer
  # - info: Text (Serialized Hash)
  # - uid: String non-nil
  # - username: String
  # - created_at: DateTime
  # - updated_at: DateTime
  # - auth_info: Text (Serialized Hash)
  # - credentials: Text (Serialized Hash)
  # - blacklisted_at: DateTime
  class Account < ActiveRecord::Base
    include Redis::Objects
    sorted_set :content_zset
    include Mixins::ContentVideos
    include Mixins::CanRefreshContent
    include Mixins::Populating
    include Mixins::Blacklisting
    # All of the accounts that this account receives content from.
    set :influencer_set

    serialize :info, Hash
    serialize :credentials, Hash
    serialize :auth_info, Hash

    belongs_to :identity
    has_and_belongs_to_many :channels,
      :class_name => 'Channel::Account', :join_table => :accounts_channels,
      :foreign_key => :account_id, :association_foreign_key => :channel_id,
      :autosave => true

    after_initialize :initialize_info_hashes
    after_destroy :delete_redis_keys

    def existing?
      false
    end

    def profile_uri
      raise InterfaceMethodNotImplemented
    end

    def thumbnail_uri
      raise InterfaceMethodNotImplemented
    end

    def description
      raise InterfaceMethodNotImplemented
    end

    def self.create_all_if_valid username
      results = []
      self.descendants.each do | descendant |
        tmp = descendant.new :uid => username
        next unless tmp.existing?
        results << tmp if tmp.save
      end
      results
    end

    # The publish interface is called by background tasks to publish a video
    # share to an external service.
    def publish share
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Account#publish.")
    end


    def influencer_ids
      influencer_set.members
    end

    def influencers
      influencer_set.map { |id| Account.find_by_id id }
    end

    def serializable_hash
      Hash[ "id" => id,
            "provider" => type.split('::').last.downcase,
            "uid" => uid,

            "username" => username,
            "profile_uri" => profile_uri,
            "thumbnail_uri" => thumbnail_uri,
            "description" => description ]
    end

    def to_channel
      Channel::Account.find_or_create_by_accounts Array(self)
    end

    def redis_keys
      [ content_zset, influencer_set ].map &:key
    end

    def delete_redis_keys
      redis_keys.each do |key|
        Redis::Objects.redis.del key
      end
    end

    # Serialized Hash attributes are initialized to prevent nil checking
    # throughout
    def initialize_info_hashes
      self.info         ||= Hash.new
      self.auth_info    ||= Hash.new
      self.credentials  ||= Hash.new
    end

    # Class Methods follow
    def Account.find_or_create_by_param string, params
      username, provider = Account.from_param string
      Account.find_or_create_by_provider_and_username provider, username, params
    end

    # Returns the `username` and `provider` of a given parameterized account.
    def Account.from_param str
      str.split("@")[0..1]
    end
  end
end
