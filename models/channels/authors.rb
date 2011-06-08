module Aji
  module Channels
    class Authors < Channel
      has_and_belongs_to_many :authors

      def populate
        authors.each_with_index do |a, i|
          if a.videos.count == 0 and a.video_source == :youtube
            yt_videos = YouTubeIt::Client.new.videos_by(
              :user => "#{a.screen_name}", :max_results => 100,
              :order_by => 'published').videos
            yt_videos.each do |v|
              Video.find_or_create(
                :title => v.title,
                :external_id => v.video_id.split(':').last,
                :description => v.description,
                :author => a,
                :source => :youtube,
                :viewable_mobile => v.noembed)            end
          end

          a.videos.members.each_with_index do |v, k|
            # Until I can write my own Redis-backed ZSet class or come up with
            # a suitable interface to Redis::Objects::SortedSet, this is a 
            # clever trick to get unique ranks for each video into a channel.
            videos[v] = "#{i + 1}#{k + 1}".to_i
          end
        end
      end
    end
  end
end
