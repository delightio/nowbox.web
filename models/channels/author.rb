module Aji
  module Channels
    class YoutubeAccount < Channel
      has_and_belongs_to_many :accounts,
        :class_name => 'Aji::ExternalAccounts::Youtube',
        :join_table => :youtube_youtube_channels, :foreign_key => :channel_id,
        :association_foreign_key => :account_id

      def populate
        accounts.each_with_index do |a, i|
          # Fetch videos from specific sources.
          if a.own_zset.members.count == 0
            yt_videos = YouTubeIt::Client.new.videos_by(
              :user => "#{a}", :order_by => 'published').videos
              yt_videos.each_with_index do |v, n|
                a.own_zset[Video.find_or_create_by_external_id(
                  v.video_id.split(':').last,
                  :title => v.title,
                  :description => v.description,
                  :author => a,
                  :source => :youtube,
                  :viewable_mobile => v.noembed).id] = v.published_at.to_i
              end
          end
        end

        a.own_zset.members.each_with_index do |v, k|
          # Until I can write my own Redis-backed ZSet class or come up with
          # a suitable interface to Redis::Objects::SortedSet, this is a 
          # clever trick to get unique ranks for each video into a channel.
          content_zset[v] = "#{i + 1}#{k + 1}".to_i
        end
      end
    end
  end
end
