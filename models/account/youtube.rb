module Aji
  class Account::Youtube < Account
    validates_presence_of :uid
    validates_uniqueness_of :uid

    after_create :set_uid_as_username

    def profile_uri
      "http://www.youtube.com/user/#{username}"
    end

    def thumbnail_uri
      info['thumbnail_uri'] || ""
    end

    def description
      info['description'] || ""
    end

    def refresh_content force=false
      new_videos = []
      refresh_lock.lock do
        return [] if recently_populated? && content_video_ids.count > 0 && !force
        vhashes = Macker::Search.new(:author => username).search
        vhashes.each do |vhash|
          video = Video.find_or_create_by_external_id vhash[:external_id], vhash
          video.update_attributes vhash unless video.populated?
          relevance = video.published_at.to_i
          push video, relevance
          new_videos << video
        end
        update_attribute :populated_at, Time.now
      end
      new_videos
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
