module Aji
  class Queues::Mention::Parse

    @queue = :mention

    # Handles incoming parse requests from various social feeds. If the mention
    # contains a valid http(s) link it will be enqueued for processing. At this
    # time there exists no efficient way to filter out non-video links as link
    # expansion will be necessary in many cases (fskcing overzealos t.co use by
    # Twitter)
    def self.perform source, data
      # Parse incoming data from various sources.
      case source
      when 'twitter'
        mention = Parsers::Tweet.parse data
      end

      # Enqueue iff the mention has a valid link.
      Resque.enqueue Queueus::Mention::Process mention if mention.has_link?
    end
  end
end
