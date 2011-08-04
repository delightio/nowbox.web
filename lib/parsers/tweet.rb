module Aji
  class Parsers::Tweet
    # Parses the JSON from Twitter and returns a `Mention`. It will also create
    # an un-authenticated `ExternalAccount::Twitter` object or retrieve an
    # existing one representing the author of the mention.
    # This method takes an optional block parameter. This block will have access
    # to the parsed tweet as a hash before it or its author are instantiated.
    # if the block returns true, the object will be created and returned,
    # otherwise the method will return early with nil.
    def self.parse json
      # HACK: This is not the best way, there should be a Json parsing
      # preprocessor which then calls the root parse method.
      case json
      when String
        # If the parse fails then sorry Charlie we just don't care.
        # Return a benign value nil.
        # TODO: Refactor messaging of the parsers to throw symbols like
        # `:invalid_json` and `:failed_filter` in order to log failure
        # reason.
        tweet_hash = MultiJson.decode json rescue return nil
      when Hash
        tweet_hash = json
      else
        raise ArgumentError.new(
          "I don't want any #{json.class} only strings and hashes.")
      end

      # Run the optional block on the tweet hash before instantiation.
      # If the block returns false then return nil and leave the method.
      # This will allow us to avoid wasting time with tweets and authors we
      # don't care about such as those which don't contain links.
      filter = if block_given? then yield tweet_hash else true end
      return nil unless filter

      # TODO: Is there a way to avoid saving this guy to DB?
      author = ExternalAccounts::Twitter.find_or_create_by_uid(
        tweet_hash['user']['id'].to_s, :user_info => tweet_hash['user'],
        :username => tweet_hash['user']['screen_name'])

      links = tweet_hash['entities']['urls'].map do |url|
        Link.new(url['expanded_url'] || url['url'])
      end

      Mention.new(
        :external_id => tweet_hash['uid'],
        :body => tweet_hash['text'],
        :published_at => tweet_hash['created_at'],
        :unparsed_data => json,
        :author => author,
        :links => links)
    end
  end
end
