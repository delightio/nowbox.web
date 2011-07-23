module Aji
  module Channels
    class YoutubeAccount < Channel
      has_and_belongs_to_many :accounts,
        :class_name => 'Aji::ExternalAccounts::Youtube',
        :join_table => :youtube_youtube_channels, :foreign_key => :channel_id,
        :association_foreign_key => :account_id

      before_create :set_title
      def self.to_title accounts; accounts.map(&:uid).join ", "; end
      def set_title; self.title = title || self.class.to_title(accounts); end

      def populate args={}
        accounts.each_with_index do |a, i|
          # Fetch videos from specific sources.
          if a.content_video_ids.count == 0 || args[:must_populate]
            yt_videos = YouTubeIt::Client.new.videos_by(
              :user => "#{a.uid}", :order_by => 'published').videos#TODO paging
            yt_videos.each_with_index do |v, n|
              video = Video.find_or_create_from_youtubeit_video v
              vid = video.id
              relevance = v.published_at.to_i
              a.push video, relevance
              content_zset[vid] = relevance
            end
            self.populated_at = Time.now
            save
          end
        end
      end

      def self.find_all_by_accounts accounts
        accounts_channels = accounts.map{ |a| a.channels }
        # Perform an intersection on all the channels from given accounts
        # using Ruby's awesome Array#inject.
        matching_channels = accounts_channels.inject(&:&)
        matching_channels.find_all { |c| c.accounts.length == accounts.length }
      end
      
      def self.find_or_create_by_usernames usernames, args={}
        accounts = usernames.map { |n| 
          ExternalAccounts::Youtube.find_or_create_by_uid :uid => n }
        found = self.find_all_by_accounts accounts
        return found.first if !found.empty?
        
        populate_if_new = args[:populate_if_new]
        args.delete :populate_if_new
        args.merge! :accounts => accounts
        channel = self.create args
        channel.populate if populate_if_new
        channel
      end
      
    end
  end
end
