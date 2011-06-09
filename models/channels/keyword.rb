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
            external_account =
              Aji::ExternalAccounts::Youtube.find_or_create_by_uid(
                v.author.name, :provider => "youtube")
            content_zset[Video.find_or_create_by_external_id(
              v.video_id.split(':').last,
              :title => v.title,
              :description => v.description,
              :external_account => external_account,
              :source => :youtube,
              :viewable_mobile => v.noembed).id] = "#{page}#{i}".to_i
          end
        end
      end
    end
  end
end
