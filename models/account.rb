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
    # The maximum amount of times a user can mention a video before they are
    # considered a spammer.
    SPAM_THRESHOLD = 3

    include Redis::Objects
    include Mixins::ContentVideos
    include Mixins::CanRefreshContent
    include Mixins::Populating
    include Mixins::Blacklisting
    include Aji::TankerDefaults::Account

    # All of the accounts that this account receives content from.
    set :influencer_set

    validates_uniqueness_of :uid, :case_sensitive => false

    serialize :info, Hash
    serialize :credentials, Hash
    serialize :auth_info, Hash

    belongs_to :identity, :class_name => 'Aji::Identity'

    has_one :user, :through => :identity
    has_and_belongs_to_many :channels,
      :class_name => 'Channel::Account', :join_table => :accounts_channels,
      :foreign_key => :account_id, :association_foreign_key => :channel_id,
      :autosave => true

    before_save :downcase_uid
    after_initialize :initialize_info_hashes
    after_save :update_tank_indexes_if_searchable
    after_destroy :delete_redis_keys, :delete_tank_indexes_if_searchable

    def profile_uri
      raise InterfaceMethodNotImplemented
    end

    def thumbnail_uri
      raise InterfaceMethodNotImplemented
    end

    def description
      raise InterfaceMethodNotImplemented
    end

    def subscriber_count
      raise InterfaceMethodNotImplemented
    end

    def realname; ""; end

    def videos_from_source
      raise InterfaceMethodNotImplemented
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

    def marked_spammer?
      Aji.redis.sismember "spammers", id
    end

    def serializable_hash
      Hash[ "id" => id,
            "provider" => type.split('::').last.downcase,
            "uid" => uid,
            "username" => username,
            "thumbnail_uri" => thumbnail_uri,
            "profile_uri" => profile_uri,
            "subscriber_count" => subscriber_count ]

            # These are available but iOS doesn't need it.
            # Extra memory neede for these has became significant on iOS.
            # "realname" => realname,
            # "description" => description
    end

    def deauthorize!
      self.identity = nil
      self.credentials.clear
      self.mentions.each{ |m| m.destroy }
      self.mentions.clear
      content_zset.clear
      influencer_set.clear
      self.stream_channel.destroy if self.respond_to? :stream_channel
      save
    end

    def to_channel
      Channel::Account.find_or_create_by_accounts Array(self)
    end

    def blacklisted_videos
      Video.where("author_id = ? AND blacklisted_at IS NOT NULL", id)
    end

    def blacklist_repeated_offender
      blacklist if blacklisted_videos.count >= 3
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

    def downcase_uid
      self.uid = uid.downcase unless uid.nil?
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
