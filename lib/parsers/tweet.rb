module Aji
  class Parsers::Tweet
    # Parses the JSON from Twitter and returns a `Mention`. It will also create
    # an un-authenticated `ExternalAccount::Twitter` object or retrieve an
    # existing one representing the author of the mention.
    def self.parse json
      # HACK: This is not the best way, there should be a Json parsing
      # preprocessor which then calls the root parse method.
      start = Time.now
      case json
      when String
        tweet_hash = MultiJson.decode json
      when Hash
        tweet_hash = json
      else
        raise ArgumentError.new(
          "I don't want any #{json.class} only strings and hashes.")
      end
      Aji.log "TIMING:casemagic: #{Time.now - start} s."

      start = Time.now
      author = ExternalAccounts::Twitter.find_or_create_by_uid(
        tweet_hash['user']['id'].to_s, :user_info => tweet_hash['user'],
        :username => tweet_hash['user']['screen_name'])
      Aji.log "TIMING:find_author: #{Time.now - start} s."

      start = Time.now
      links = tweet_hash['entities']['urls'].map do |url|
        Link.new(url['expanded_url'] || url['url'])
      end
      Aji.log "TIMING:link_iteration: #{Time.now - start} s."

      start = Time.now
      Mention.new(
        :external_id => tweet_hash['uid'],
        :body => tweet_hash['text'],
        :published_at => tweet_hash['created_at'],
        :unparsed_data => json,
        :author => author,
        :links => links)
      Aji.log "TIMING:mention_instantiation: #{Time.now - start} s."
    end
  end
end
