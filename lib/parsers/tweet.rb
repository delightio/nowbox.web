module Aji
  class Parsers::Tweet
    # Parses the JSON from Twitter and returns a `Mention`. It will also create
    # an un-authenticated `ExternalAccount::Twitter` object or retrieve an
    # existing one representing the author of the mention.
    def self.parse json
      # HACK: This is not the best way, there should be a Json parsing
      # preprocessor which then calls the root parse method.
      case json.class
      when String
        tweet_hash = MultiJson.decode json
      when Hash
        tweet_hash = json
      else
        raise ArgumentError.new(
          "I don't want any #{json.class} only strings and hashes.")
      end
      author = ExternalAccounts::Twitter.find_or_create_by_uid(
        tweet_hash['user']['id'].to_s, :user_info => tweet_hash['user'],
        :username => tweet_hash['user']['screen_name'])
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
