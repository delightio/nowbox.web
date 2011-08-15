module Aji
  class Account::Youtube < Account
    after_create :set_uid_as_username

    def profile_uri; "http://www.youtube.com/user/#{username}"; end

    def thumbnail_uri
      @thumbnail_uri ||=
        begin
          r = HTTParty.get(
            "http://gdata.youtube.com/feeds/api/users/#{uid}?v=2")
            match = r.body.match(/<media:thumbnail url='(.*)'/)
            if match then match[1] else "" end
        end
    end

    def refresh_content force=false
      start = Time.now
      new_videos = []
      refresh_lock.lock do
        return if recently_populated? && content_video_ids.count > 0 && !force
        vhashes = Macker::Search.new(:author => username).search
        vhashes.each do |vhash|
          video = Video.find_or_create_by_external_id vhash[:external_id], vhash
          relevance = video[:published_at].to_i
          push video, relevance
          new_videos << video
        end
        update_attribute :populated_at, Time.now
      end

      Aji.log(
        "Account::Youtube[#{id}, '#{username}' ]#refresh_content took #{Time.now-start} s.")
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
