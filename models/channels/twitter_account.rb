module Aji
  module Channels
    class TwitterAccount < Channel
      belongs_to :account, :class_name => 'Aji::ExternalAccounts::Twitter'
      before_create :set_default_title
      #after_create :populate

      USER_TIMELINE_URL = "http://api.twitter.com/1/statuses/user_timeline.json"

      # HACK: This is long, complex, blocking, and tightly coupled. A good
      # candidate for refactoring later.
      def populate
        tweets = HTTParty.get(USER_TIMELINE_URL, :query => { :count => 200,
            :screen_name => account.username, :include_entities => true },
            :parser => Proc.new{|body| MultiJson.decode body}).parsed_response
        mentions = tweets.map { |tweet| Parsers::Tweet.parse tweet }
        mentions.map(&:save)
        mentions.each do |m|
          m.links.each do |link|
            next unless link.video?
            video = Video.find_or_create_by_source_and_external_id(link.type,
              link.external_id)
            puts video.inspect
            push video
          end
        end

        # Since we want to use the videos right away we will autopopulate them.
        content_videos.map(&:populate)
        update_attribute :populated_at, Time.now
      end

      def thumbnail_uri
        account.thumbnail_uri
      end

      # Class methods below
      def self.find_or_create_by_account account, params={}
        account.channel ||= Channels::TwitterAccount.create(params.merge(
          :account => account))
      end
      # Private instance methods below.
      private
      def set_default_title
        self.title ||= "@#{account.username}'s Tweeted Videos"
      end
    end
  end
end
