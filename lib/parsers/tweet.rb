module Aji
  class Parsers::Tweet
    # Parses the JSON from Twitter and returns a `Mention`. It will also create
    # an un-authenticated `ExternalAccount::Twitter` object or retrieve an
    # existing one representing the author of the mention.
    def self.parse json
      tweet_hash = MultiJson.decode json
      Mention.new(
        :external_id => tweet_hash['uid'],
        :body => tweet_hash['text'],
        :unparsed_data => json,
        :author => ExternalAccount::Twitter.find_or_create_by_provider_uid(
          'twitter', tweet_hash['user']['id']))
    end
  end
end
