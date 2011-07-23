module Aji
  module ExternalAccounts
    # ## ExternalAccounts::Youtube Schema Extensions
    # TODO: Currently overloading ExternalAccount#uid to store youtube
    # username. This is more than likely not the actual Youtube uid so we
    # sould determine what it is and store it in the user_info hash with the
    # other user params.
    class Youtube < ExternalAccount
      has_and_belongs_to_many :channels,
        :class_name => 'Channels::YoutubeAccount',
        :join_table => :youtube_youtube_channels,
        :foreign_key => :account_id, :association_foreign_key => :channel_id

      def username; uid; end
      def profile_uri; "http://www.youtube.com/user/#{uid}"; end

      def populate args={}
        start = Time.now
        populating_lock.lock do
          return if recently_populated? && args[:must_populate].nil?
          if content_video_ids.count == 0 || args[:must_populate]
            yt_videos = YouTubeIt::Client.new.videos_by(
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
        Aji.log :INFO, "ExternalAccounts::Youtube[#{id}, '#{self.username}' ]#populate #{args.inspect} took #{Time.now-start} s."
      end
      
    end
  end
end
