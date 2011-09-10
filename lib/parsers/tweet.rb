module Aji
  class Parsers::Tweet
    # Parses the JSON from Twitter and returns a `Mention`. It will also create
    # an un-authenticated `Account::Twitter` object or retrieve an
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
        raise ArgumentError,
          "I don't want any #{json.class} only strings and hashes. " +
          json.inspect
      end

      # Run the optional block on the tweet hash before instantiation.
      # If the block returns false then return nil and leave the method.
      # This will allow us to avoid wasting time with tweets and authors we
      # don't care about such as those which don't contain links.
      #
      # IDEA: What if instead of only using the block as a filter, what if we
      # completely yielded to the block so that it has complete control over
      # what to do. I think this idea falls down because it means repetition of
      # the mention instantiation code but there has to be a way to match this
      # cleanly with minimal db interaction.
      filter = if block_given? then yield tweet_hash else true end
      return nil unless filter

      # TODO: Is there a way to avoid saving this guy to DB?
      author = Account::Twitter.find_by_username(
        tweet_hash['user']['screen_name'])
      author ||= Account::Twitter.new :uid => tweet_hash['user']['uid'],
        :username => tweet_hash['user']['screen_name'],
        :info => tweet_hash['user']

      links = tweet_hash['entities']['urls'].map do |url|
        Link.new(url['expanded_url'] || url['url'])
      end

      mention = Mention.new(
        :uid => tweet_hash['uid'],
        :body => tweet_hash['text'],
        :published_at => tweet_hash['created_at'],
        :unparsed_data => json,
        :author => author,
        :source => 'twitter',
        :links => links)
    end
  end
end
