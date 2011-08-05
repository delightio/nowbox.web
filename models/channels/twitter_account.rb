module Aji
  module Channels
    class TwitterAccount < Channel
      belongs_to :account, :class_name => 'Aji::ExternalAccounts::Twitter'
      before_create :set_default_title
      #after_create :populate

      USER_TIMELINE_URL = "http://api.twitter.com/1/statuses/user_timeline.json"

      # HACK: This is long, complex, blocking, and tightly coupled. A good
      # candidate for refactoring later.
      def populate args={}
        start = Time.now
        populating_lock.lock do 
          return if recently_populated? && args[:must_populate].nil?
          tweets = HTTParty.get(USER_TIMELINE_URL, :query => { :count => 200,
              :screen_name => account.username, :include_entities => true },
              :parser => Proc.new{|body| MultiJson.decode body}).parsed_response
          mentions = tweets.map { |tweet| Parsers::Tweet.parse tweet }
          mentions.map(&:save)
          mentions.each do |m|
            m.links.each do |link|
              next unless link.video?
              video = Video.find_or_create_by_external_id_and_source(
                link.external_id, link.type)
              video.populate
              push video
            end
          end
          # Since we want to use the videos right away we will autopopulate them.
          update_attribute :populated_at, Time.now
        end
        Aji.log :INFO, "Channels::TwitterAccount[#{id}, '#{account.uid}', #{account.username}]#populate #{args.inspect} took #{Time.now-start} s."
      end

      def thumbnail_uri
        account.thumbnail_uri
      end

      # Class methods below
      def self.find_or_create_by_account account, args={}
        populate_if_new = args.delete :populate_if_new
        args.merge! :account => account
        account.channel ||= self.create args
        account.channel.populate if populate_if_new
        account.channel
      end
      
      def self.find_or_create_by_username username, args={}
        account = ExternalAccounts::TwitterAccount.find_or_create_by_username username
        self.find_or_create_by_account account args
      end
      
      # Private instance methods below.
      private
      def set_default_title
        self.title ||= "@#{account.username}'s Tweeted Videos"
      end
    end
  end
end
