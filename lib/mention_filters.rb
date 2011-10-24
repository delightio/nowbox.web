module Aji
  module MentionFilters
    module Twitter
      def reject_no_videos urls
        return false if urls.empty?
        urls.any? { |u| Link.new(u['expanded_url'] || u['url']).video? }
      end

      def reject_existing_uid uid
        Mention.find_by_uid_and_source uid, 'twitter'
      end
    end

    module Facebook
      def reject_no_videos hash
        return false unless hash['type'] == 'video' and hash['link']
        Link.new(hash['link']).video?
      end

      def reject_existing_uid uid
        Mention.find_by_uid_and_source uid, 'facebook'
      end
    end

    def [] source
      { 'twitter' => Twitter, 'facebook' => Facebook }
    end
  end
end
