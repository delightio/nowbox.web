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
    serialize :user_info, Hash
    serialize :credentials, Hash
    belongs_to :identity

    has_and_belongs_to_many :channels,
      :class_name => 'Channel::Account', :join_table => :accounts_channels,
      :foreign_key => :account_id, :association_foreign_key => :channel_id,
      :autosave => true

    validates_uniqueness_of :uid, :scope => :type

    sorted_set :content_zset
    include Mixins::ContentVideos
    lock :refresh, :expiration => 10.minutes
    include Mixins::Populating
    include Mixins::Blacklisting
    # All of the accounts that this account receives content from.
    set :influencer_set

    # The publish interface is called by background tasks to publish a video
    # share to an external service.
    def publish share
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Account#publish.")
    end

    # The `refresh_content` method for accounts pulls content generated by the
    # account into the database and stores it in a Redis ZSet specific to each
    # account. The method takes a single boolean argument `force` which can be
    # used to force a refresh in spite of a recently completed refresh.
    # The method returns no useful value.
    def refresh_content force=false
      raise InterfaceMethodNotImplemented.new(
        "#{self.class} must override Account#refresh_content.")
    end

    def influencer_ids
      influencer_set.members
    end

    def influencers
      influencer_set.map { |id| Account.find_by_id id }
    end

    def profile_uri; raise InterfaceMethodNotImplemented; end

    def thumbnail_uri; raise InterfaceMethodNotImplemented; end

    def serializable_hash
      Hash[ "id" => id,
            "provider" => type.split('::').last.downcase,
            "uid" => uid,

            "username" => username,
            "profile_uri" => profile_uri,
            "thumbnail_uri" => thumbnail_uri ]
    end

    def to_channel
      Channel::Account.find_or_create_by_accounts Array(self)
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
