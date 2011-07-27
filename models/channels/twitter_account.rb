module Aji
  class Channels::TwitterAccount < Channel
    belongs_to :account, :class_name => 'Aji::ExternalAccounts::Twitter'
    before_create :set_default_title
    TWITTER_API_URL =
      "http://api.twitter.com/1/statuses/user_timeline.json?count=50&include_entities=true"


    # Class methods below
    def self.find_or_create_by_account account, params={}
      account.channel ||= Channels::TwitterAccount.create(params.merge(
        :account => account))
    end

    def thumbnail_uri
      ""
    end

    # HACK: This is long, complex, and tightly coupled. A good later refactor
    # candidate.
    def populate
      puts account.username
      resp = HTTParty.get(
        TWITTER_API_URL + "&screen_name=#{account.username}")
      tweets = resp.parsed_response
      puts "Tweets:#{tweets.class} => #{tweets.inspect}"
      puts "Firsttweet:#{tweets.first.class} => #{tweets.first.inspect}"
      mentions = tweets.map { |tweet| Parsers::Tweet.parse tweet }
      mentions.map(&:save)
      mentions.each_with_index do |m, i|
        m.links.each do |link|
          next unless link.video?
          content_zset[Video.find_or_create_by_source_and_external_id(
            link.type, link.external_id)] = i
        end
      end
    end

    # Private instance methods below.
    private
    def set_default_title
      self.title ||= "@#{account.username}'s Tweeted Videos"
    end
  end
end
