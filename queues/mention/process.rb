module Aji
  module Queues
    module Mention
      class Process
        extend WithDatabaseConnection

        @queue = :mention

        def self.perform source, data, destination
          # NOTE: What if, instead of providing a destination object, or channel
          # id, we instead supply the key to a redis zset? This would replace
          # the push_recent function of Trending videos and give us one fewer
          # objects to instantiate as well as less magic and more flexibility
          # when using this queue in Redis. For example, currently there is no
          # way to enqueue this job to run with an account as destiniation, it
          # must be run inline by calling Process.perform and supplying the
          # destination object.
          destination = case destination
                        when String, Fixnum
                          Channel.find destination
                        else
                          destination
                        end

          # Short circuit parser to return nil if the tweet has no urls.
          mention = self.parse source, data

          # TODO: Refactor into Mention#{unsuitable,unfit,invalid}
          if mention.nil? || mention.author.blacklisted? || !mention.has_links?
            Aji.log "#{data} passed filter with no links." if
              mention && !mention.has_links?
            return
          end

          mention.author.blacklist && return if mention.spam?

          mention.links.each do |link|

            # TODO: Update to include all valid link types.
            next unless link.video? && link.type == 'youtube'
            video = Aji::Video.find_or_create_by_external_id_and_source(
              link.external_id, link.type)

              # NOTE: Is this really necessary? Too harsh?
              mention.author.blacklist && next if video.blacklisted?

              mention.videos << video
              # TODO: Find out why RecordNotUnique is being raised instead of
              # save failing with errors.
              mention.save or Aji.log(
                "Couldn't save #{mention.inspect} for #{mention.errors.inspect}")
              destination_channel.push_recent video
          end
        rescue => e
          Aji.log "Can't process mention: #{data.inspect}. Exception: #{e}"
          Resque.enqueue Queues::Mention::Examine, source, data, destination
        end

        # Handles incoming parse requests from various social feeds. If the mention
        # contains a valid http(s) link it will be enqueued for processing. At this
        # time there exists no efficient way to filter out non-video links as link
        # expansion will be necessary in many cases (fskcing overzealos t.co use by
        # Twitter)
        def self.parse source, data
          case source
          when 'twitter'
            mention = Parsers::Tweet.parse data do |tweet_hash|
              self.video_in_links? tweet_hash
            end
          else
            Aji.log :WARN, "Attempt to process #{data} from #{source}. Unknown"
            # TODO: Add benign return value here.
          end
        end

        # Extracts links (if any) from the tweet and determines if they contain
        # videos. Returns true if it does, otherwise false.
        def self.video_in_links? tweet_hash
          return false if tweet_hash['entities']['urls'].empty?

          tweet_hash['entities']['urls'].map do |url|
            Link.new(url['expanded_url'] || url['url']).video?
          end.inject do |acc, bool| acc ||= bool end
        end
      end
    end
  end
end
