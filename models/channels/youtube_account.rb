module Aji
  module Channels
    class YoutubeAccount < Channel
      has_and_belongs_to_many :accounts,
        :class_name => 'Aji::ExternalAccounts::Youtube',
        :join_table => :youtube_youtube_channels, :foreign_key => :channel_id,
        :association_foreign_key => :account_id

      def serializable_hash options={}
        h = super
        # TODO: Use a before_create hook to create the title. We should do the
        # same for Keywords as well.
        h["title"] = title || (accounts.map(&:uid).join ", ")
        h
      end

      def populate
        accounts.each_with_index do |a, i|
          # Fetch videos from specific sources.
          if a.own_zset.members.count == 0
            yt_videos = YouTubeIt::Client.new.videos_by(
              :user => "#{a.uid}", :order_by => 'published').videos
            yt_videos.each_with_index do |v, n|
              a.own_zset[Video.find_or_create_from_youtubeit_video(v).id] =
                v.published_at.to_i
            end
          end

          a.own_zset.members.each_with_index do |v, k|
            # Until I can write my own Redis-backed ZSet class or come up with
            # a suitable interface to Redis::Objects::SortedSet, this is a
            # clever trick to get unique ranks for each video into a channel.
            content_zset[v] = "#{i + 1}#{k + 1}".to_i
          end
        end
        self.populated_at = Time.now
        save
      end

      def self.find_by_accounts accounts
        accounts_channels = accounts.map{ |a| a.channels }
        # Perform an intersection on all the channels from given accounts
        # using Ruby's awesome Array#inject.
        matching_channels = accounts_channels.inject(&:&)
        matching_channels.find{ |c| c.accounts.length == accounts.length }
      end
      
      def self.find_or_create_by_usernames usernames, args={}
        accounts = usernames.map { |n| 
          ExternalAccounts::Youtube.find_or_create_by_uid :uid => n }
        found = self.find_by_accounts accounts
        return found if found
        
        channel = self.create :accounts => accounts, :title => args[:title]
        channel.populate if args[:populate_if_new]
        channel
      end
      
    end
  end
end
