module Aji
  class Account::Youtube < Account
    include Aji::TankerDefaults::Account

    validates_presence_of :uid
    validates_uniqueness_of :uid

    before_create :get_info_from_youtube_api
    after_create :set_uid_as_username

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

    def self.create_if_existing uid
      found = find_by_uid uid
      return found if found

      new_account = new :uid => uid
      return nil unless new_account.existing?

      # Exists but we don't have it
      # Search db again just in case the account wasn't indexed for
      # other reasons, e.g., not enough content videos
      Account::Youtube.find_or_create_by_uid uid
    end

    def refreshed?
      not thumbnail_uri.empty?
    end

    def refresh_info
      get_info_from_youtube_api
      save
    end

    def background_refresh_info
      Resque.enqueue Queues::RefreshChannelInfo, id
    end

    # Fetch information from youtube, returns the new info hash upon success
    # and false otherwise.
    def get_info_from_youtube_api
      self.info = api.author_info
    end

    def api
      @api ||= YoutubeAPI.new uid
    end

    # A Youtube Account's uid is it's username. Let's set uid elsewhere and
    # set the username to be equal within the method.
    def set_uid_as_username
      update_attribute :username, self.uid
    end
    private :set_uid_as_username

    def set_provider
      update_attribute :provider, 'youtube'
    end
    private :set_provider

  end
end
