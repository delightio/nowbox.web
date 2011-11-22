module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::CanRefreshContent
    include Mixins::Formatters::Facebook
    include Aji::TankerDefaults::Account

    has_many :mentions, :foreign_key => :author_id, :dependent => :destroy

    belongs_to :stream_channel, :class_name => 'Aji::Channel::FacebookStream',
      :foreign_key => :stream_channel_id, :dependent => :destroy

    # Use an alias to allow Facebook accounts to implement the same protocal as
    # Channel::Trending without the need for a recent_zset buffer.
    alias_method :push_recent, :push

    def refresh_content force=false
      super force do |new_videos|
        api.video_mentions_i_post.each do |m|
          m.videos.each do |v|
            v.populate do |video|
              new_videos << video
              push video, m.published_at
            end
          end
        end
      end
    end

    def description
      info['bio']
    end

    def thumbnail_uri
      "http://graph.facebook.com/#{uid}/picture"
    end

    def profile_uri
      info['link']
    end

    def realname
      info["name"]
    end

    def subscriber_count
      0 # TODO: don't we get number of friends back?
    end

    def has_token?
      credentials.key? 'token'
    end

    def authorized?
      has_token?
    end

    def spamming_video? video
      mentions.latest.select{ |m| m.has_video? video }.count > SPAM_THRESHOLD
    end

    def publish share
      api.publish *format(share)
    end

    def synchronized_at
      if stream_channel.nil? then nil else stream_channel.populated_at end
    end

    def api
      @api ||= FacebookAPI.new credentials['token']
    end

    def build_stream_channel
      self.stream_channel ||= Channel::FacebookStream.create :owner => self,
        :title => realname

      save and stream_channel.refresh_content
      stream_channel
    end

    def self.from_auth_hash auth_hash
      find_or_initialize_by_uid_and_type(auth_hash['uid'],
        self.to_s).tap do |account|
          account.uid = auth_hash['uid']
          account.credentials = auth_hash['credentials']
          account.username = auth_hash['extra']['user_hash']['username'] || ""
          account.auth_info = auth_hash
          account.info = auth_hash['extra']['user_hash']
          account.save!
        end
    end

    private
    def set_provider
      update_attribute :provider, 'facebook'
    end
  end
end
