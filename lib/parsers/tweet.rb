module Aji
  class Parsers::Tweet
    # Parses the JSON from Twitter and returns a `Mention`. It will also create
    # an un-authenticated `ExternalAccount::Twitter` object or retrieve an
    # existing one representing the author of the mention.
    def self.parse json
      tweet_hash = MultiJson.decode json
      author = ExternalAccounts::Twitter.find_or_create_by_uid(
        tweet_hash['user']['id'].to_s)
      links = tweet_hash['entities']['urls'].map do |url|
        Link.new(url['expanded_url'] || url['url'])
      end

      Mention.new(
        :external_id => tweet_hash['uid'],
        :body => tweet_hash['text'],
        :unparsed_data => json,
        :author => author,
        :links => links)
    end
  end
end
