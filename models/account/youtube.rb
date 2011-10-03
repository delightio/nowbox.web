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

    def refresh_content force = false
      super force do |new_videos|
        videos_hash = []
        vhashes = Macker::Search.new(:author => username).search
        videos = vhashes.map do |vhash|
          Video.find_or_create_by_external_id vhash[:external_id], vhash
        end

        videos.each do |v|
          next if has_content_video? v
          v.populate do |video|
            push video, video.published_at
            new_videos << video
          end
        end
      end
    end

    # If a username is a valid and true youtube user, then we'll
    # get data back from Youtube indicating their profile API which
    # we can then use to ascertain their existence.
    def existing?
      api.valid_uid? uid
    end

    # Fetch information from youtube, returns the new info hash upon success
    # and false otherwise.
    def get_info_from_youtube_api
      info = api.author_info uid
    end

    def api
      @api ||= YoutubeAPI.new
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
