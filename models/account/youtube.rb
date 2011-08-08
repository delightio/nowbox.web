module Aji
  class Account::Youtube < Account
    has_and_belongs_to_many :channels,
      :class_name => 'Channels::YoutubeAccount',
      :join_table => :youtube_youtube_channels,
      :foreign_key => :account_id, :association_foreign_key => :channel_id
    after_create :set_uid_as_username

    def username; uid; end
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

    def populate args={}
      start = Time.now
      populating_lock.lock do
        return if recently_populated? && args[:must_populate].nil?
        if content_video_ids.count == 0 || args[:must_populate]
          videos = Macker::Search.new(:author => username).search
          videos.each do |v|
            v[:author] = self
            v.delete :author_username
            video = Video.find_or_create_by_external_id v[:external_id], v
            relevance = v[:published_at].to_i
            push video, relevance
          end
        end
        update_attribute :populated_at, Time.now
      end

      Aji.log(
        "Account::Youtube[#{id}, '#{username}' ]#populate #{args.inspect} took #{Time.now-start} s.")
    end

    private
    # A Youtube Account's uid is it's username. Let's set uid elsewhere and
    # set the username to be equal within the method.
    def set_uid_as_username
      update_attribute :username, self.uid
    end
  end
end
