module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::CanRefreshContent
    include Aji::TankerDefaults::Account

    validates_presence_of :uid
    validates_uniqueness_of :uid

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

    def authorized?
      credentials.key? 'token'
    end

    def spamming_video? video
      mentions.latest.select{ |m| m.has_video? video }.count > SPAM_THRESHOLD
    end

    def api
      @api ||= FacebookAPI.new credentials['token']
    end

    def update_from_auth_info auth_hash
      self.credentials = auth_hash['credentials']
      self.username = auth_hash['extra']['user_hash']['username']
      self.info = auth_hash['extra']['user_hash']
      save
      self
    end

    def create_stream_channel
      self.stream_channel ||= Channel::FacebookStream.create :owner => self,
        :title => "Facebook Stream"
      save and stream_channel
    end
  end
end
