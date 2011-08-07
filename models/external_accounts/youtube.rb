module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Youtube Schema Extensions
    class Youtube < ExternalAccount
      has_and_belongs_to_many :channels,
        :class_name => 'Channels::YoutubeAccount',
        :join_table => :youtube_youtube_channels,
        :foreign_key => :account_id, :association_foreign_key => :channel_id
      after_create :set_uid_as_username

      def username; uid; end
      def profile_uri; "http://www.youtube.com/user/#{username}"; end

      def thumbnail_uri # LH #120
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
            yt_videos = Aji.youtube_client.videos_by(
                          :user => "#{uid}",
                          :order_by => 'published').videos#TODO paging
            yt_videos.each do |v|
              video = Video.find_or_create_from_youtubeit_video v
              relevance = v.published_at.to_i
              push video, relevance
            end
          end
          self.populated_at = Time.now
          save
        end
        Aji.log :INFO,
          "ExternalAccounts::Youtube[#{id}, '#{username}' ]#populate #{args.inspect} took #{Time.now-start} s."
      end
      private
      # A Youtube Account's uid is it's username. Let's set uid elsewhere and
      # set the username to be equal within the method.
      def set_uid_as_username
        update_attribute :username, self.uid
      end
    end
  end
end
