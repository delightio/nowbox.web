module Aji
  class Account::Youtube < Account
    include Aji::TankerDefaults::Account

    validates_presence_of :uid
    validates_uniqueness_of :uid

    before_create :get_info_from_youtube_api
    after_create :set_uid_as_username

    def profile_uri
      info['profile_uri']
    end

    def thumbnail_uri
      info['thumbnail_uri'] || ""
    end

    def description
      info['description'] || ""
    end

    def realname
      info['realname'] || ""
    end

    def videos_from_source
      videos_hash = []
      vhashes = Macker::Search.new(:author => username).search
      vhashes.each do |vhash|
        video = Video.find_or_create_by_external_id vhash[:external_id], vhash
        video.update_attributes vhash unless video.populated?
        if video.populated?
          videos_hash << ({:video => video, :relevance => video.published_at.to_i})
        end
      end
      videos_hash
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
      youtube_data = api.author_info uid
      info['thumbnail_uri'] = youtube_data.thumbnail_uri
      info['profile_uri'] = youtube_data.profile_uri
      info['description'] = youtube_data.description
      info['realname'] = youtube_data.realname
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
