module Aji
  # ## Account::Twitter Schema Extensions
  # - recent_zset: Redis::Objects::SortedSet
  class Account::Twitter < Account

    include Redis::Objects
    include Mixins::RecentVideos
    include Aji::TankerDefaults::Account
    include Mixins::Formatters::Twitter

    has_many :mentions, :foreign_key => :author_id, :dependent => :destroy

    belongs_to :stream_channel, :class_name => 'Aji::Channel::TwitterStream',
      :foreign_key => :stream_channel_id, :dependent => :destroy

    after_create :set_provider

    def profile_uri
      "http://twitter.com/#{username}"
    end

    def thumbnail_uri
      info['profile_image_url'] ||
        "http://api.twitter.com/1/users/profile_image/#{username}.json"
    end

    def realname
      info['name'] || ""
    end

    def description
      info['description'] || ""
    end

    def subscriber_count
      info['followers_count'] || 0
    end

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

    def publish share
      api.publish format(share)
    end

    def mark_spammer
      Aji.redis.sadd "spammers", id
      mentions.each { |m| m.mark_spam }
      blacklist
    end

    def spamming_video? video
      mentions.latest.select{ |m| m.has_video? video }.count > SPAM_THRESHOLD
    end

    def authorized?
      credentials.has_key? 'token' and credentials.has_key? 'secret'
    end

    def existing?
      api.valid_uid? uid
    end

    def api
      @api ||= if authorized?
                 TwitterAPI.new token: credentials['token'],
                   secret: credentials['secret']
               else
                 TwitterAPI.new uid: uid
               end
    end

    def synchronized_at
      if stream_channel.nil? then nil else stream_channel.populated_at end
    end

    def build_stream_channel
      self.stream_channel ||= Channel::TwitterStream.create :owner => self,
        :title => username
      save and stream_channel.refresh_content
      stream_channel
    end

    def set_provider
      update_attribute :provider, 'twitter'
    end
    private :set_provider

    def self.from_auth_hash auth_hash
      find_or_initialize_by_uid_and_type(auth_hash['uid'],
        self.to_s).tap do |account|
          account.uid = auth_hash['uid']
          account.credentials = auth_hash['credentials']
          account.username = auth_hash['extra']['user_hash']['screen_name']
          account.info = auth_hash['extra']['user_hash']
          account.auth_info = auth_hash
          account.save!
        end
    end
  end
end

