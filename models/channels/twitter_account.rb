module Aji
  module Channels
    class TwitterAccount < Channel
      belongs_to :account, :class_name => 'Aji::ExternalAccounts::Twitter'
      before_create :set_default_title
      after_create :populate
      TWITTER_API_URL =
        "http://api.twitter.com/1/statuses/user_timeline.json?count=200&include_entities=true"

      def thumbnail_uri; account.thumbnail_uri; end

      # HACK: This is long, complex, blocking, and tightly coupled. A good
      # candidate for refactoring later.
      def populate
        resp = HTTParty.get(
          TWITTER_API_URL + "&screen_name=#{account.username}")
          tweets = resp.parsed_response
          mentions = tweets.map { |tweet| Parsers::Tweet.parse tweet }
          mentions.map(&:save)
          mentions.each_with_index do |m, i|
            m.links.each do |link|
              next unless link.video?
              push Video.find_or_create_by_source_and_external_id(
                link.type, link.external_id)
            end
          end

          # Since we want to use the videos right away we will autopopulate them.
          content_videos.map(&:populate)
          update_attribute :populated_at, Time.now
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
