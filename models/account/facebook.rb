module Aji
  class Account::Facebook < Account
    include Redis::Objects
    include Mixins::CanRefreshContent

    validates_presence_of :uid
    validates_uniqueness_of :uid

    # Use an alias to allow Facebook accounts to implement the same protocal as
    # Channel::Trending without the need for a recent_zset buffer.
    alias_method :push_recent, :push

    def refresh_content force=false
      super force do |new_videos|
        mentions = api.video_mentions_i_post
        mentions.each do |mention|
          mention.videos.each do |video|
            video.populate unless video.populated?

            if video.populated?
              new_videos << video
              push video, mention.published_at
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

    def authorized?
      credentials.key? 'token'
    end

    def api
      @api ||= FacebookAPI.new credentials['token']
    end

  end
end
