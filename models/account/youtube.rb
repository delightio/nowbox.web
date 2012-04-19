module Aji
  class Account::Youtube < Account

    before_create :get_info_from_youtube_api, :unless => :authorized?

    has_many :videos, :foreign_key => :author_id, :dependent => :destroy

    def profile_uri
      info['profile']
    end

    def thumbnail_uri
      info['thumbnail']
    end

    def description
      info['about_me']
    end

    def realname
      info.fetch('first_name', '') + info.fetch('last_name', '')
    end

    def subscriber_count
      info['subscriber_count'] || 0
    end

    def video_upload_count
      info['video_upload_count']
    end

    def refresh_content force = false
      super force do |new_videos|
        api.uploaded_videos.each do |video|
          new_videos << video
          push video, video.published_at
        end
      end
    end

    # If a username is a valid and true youtube user, then we'll
    # get data back from Youtube indicating their profile API which
    # we can then use to ascertain their existence.
    def existing?
      api.valid_uid?
    end

    def valid_info?
      not thumbnail_uri.empty?
    end

    def authorized?
      credentials.has_key? 'token' and credentials.has_key? 'secret'
    end

    def refresh_info
      get_info_from_youtube_api
      if valid_info? then save else false end
    end

    def background_refresh_info
      Resque.enqueue Queues::RefreshAccountInfo, id
    end

    # Fetch information from youtube, returns the new info hash upon success
    # and false otherwise.
    def get_info_from_youtube_api
      self.info = api.author_info
      self.username = unless info['username'].empty?
                        info['username']
                      else
                        uid
                      end
    end

    def api
      @api ||=  if authorized?
                  BackgroundYoutubeAPI.new uid, credentials['token'],
                    credentials['secret']
                else
                  YoutubeAPI.new uid
                end
    end

    def set_provider
      update_attribute :provider, 'youtube'
    end
    private :set_provider

    def forbidden_words_in_username?
      pos = username.downcase =~ /vevo$/
      pos != nil
    end

    def available?
      return false if blacklisted? || forbidden_words_in_username?

      true
    end

    def on_favorite video
      api.add_to_favorites video.external_id if video.source == :youtube
    end

    def on_unfavorite video
      api.remove_from_favorites video.external_id if video.source == :youtube
    end

    def on_enqueue video
      api.add_to_watch_later video.external_id if video.source == :youtube
    end

    def on_dequeue video
      api.remove_from_watch_later video.external_id if video.source == :youtube
    end

    def on_subscribe channel
      api.subscribe_to channel.accounts.first.uid if channel.youtube_channel?
    end

    def on_unsubscribe channel
      api.unsubscribe_from channel.accounts.first.uid if channel.youtube_channel?
    end

    def self.create_if_existing uid
      account = find_by_lower_uid(uid)
      return account unless account.nil?

      if YoutubeAPI.api.valid_uid? uid
        find_or_create_by_lower_uid uid
      end
    end

    def blacklisted_videos
      Video.where("author_id = ? AND blacklisted_at IS NOT NULL", id)
    end

    def blacklist_repeated_offender
      percent = blacklisted_videos.count * 100 /  videos.count
      if percent >= 50
        blacklist
        Aji.log "Account::Youtube[#{id}] is blacklisted due to too many unviewable videos (#{percent} percent)"
      end
    end

    def authorize! user
      Aji.log "User[#{user.id}] authorized Account::Youtube[#{id}] (last sync'ed: #{synchronized_at})"
      YoutubeSync.new(self).background_push_and_synchronize!
    end

    def unlink_and_destroy
      if user
        Aji.log "Unlinking User[#{user.id}]..."
        user.identity.accounts.delete self
      end
      Aji.log "Destroying self..."
      destroy
    end

    def self.from_auth_hash auth_hash
      info = YoutubeAPI::DataGrabber.new(auth_hash['uid'],
        auth_hash['extra']['user_hash']).build_hash

      find_or_initialize_by_uid_and_type(info['uid'],
        self.to_s).tap do |account|
          account.uid = info['uid']
          account.username = info['username']
          account.credentials = auth_hash['credentials']
          account.info = info
          account.auth_info = auth_hash
          account.save!
        end
    end
  end
end

