module Aji
  module Channels
    # ## Keyword Schema Additions
    # - keywords: Serialized array of strings
    class Keyword < Channel
      serialize :keywords

      def populate
        (1..3).each do |page|
          vids = YouTubeIt::Client.new.videos_by(:query => keywords.join(' '),
                                                 :page => page).videos
          vids.each_with_index do |v, i|
            author = Aji::Author.find_or_create_by_screen_name(v.author.name,
              :video_source => :youtube)
            content_zset[Video.find_or_create_by_external_id(
              v.video_id.split(':').last,
              :title => v.title,
              :description => v.description,
              :author => author,
              :source => :youtube,
              :viewable_mobile => v.noembed).id] = "#{page}#{i}".to_i
          end
        end
      end
    end
  end
end
