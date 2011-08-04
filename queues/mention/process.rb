module Aji
  module Queues
    module Mention
      class Process

        @queue = :mention

        def self.perform source, data
          start = Time.now
          # Short circuit parser to return nil if the tweet has no urls.
          mention = self.parse source, data do |tweet_hash|
            !tweet_hash['entities']['urls'].empty?
          end

          # TODO: Refactor into Mention#{unsuitable,unfit,invalid}
          start = Time.now
          if mention.nil? || mention.author.blacklisted? || !mention.has_links?
            Aji.log "Mention #{mention.inspect} was not suitable for proccessing."
            return
          end

          start = Time.now
          mention.links.each do |link|
            # TODO: Update to include all valid link types.
            next unless link.video? && link.type == 'youtube'
            video = Aji::Video.find_or_create_by_external_id_and_source(
              link.external_id, link.type)

              if video.blacklisted? || mention.spam?
                mention.author.blacklist
                next
              end
              mention.videos << video
              mention.save or Aji.log(
                "Couldn't save #{mention.inspect} for #{mention.errors.inspect}")
                Aji::Channel.trending.push_recent video
          end
        end

        # Handles incoming parse requests from various social feeds. If the mention
        # contains a valid http(s) link it will be enqueued for processing. At this
        # time there exists no efficient way to filter out non-video links as link
        # expansion will be necessary in many cases (fskcing overzealos t.co use by
        # Twitter)
        def self.parse source, data
          case source
          when 'twitter'
            start = Time.now
            mention = Parsers::Tweet.parse data
            Aji.log "TIMING:total_parse: #{Time.now - start} s."
            mention
          else
            Aji.log :WARN, "Attempt to process #{data} from #{source}. Unknown"
            # TODO: Add benign return value here.
          end
        end
      end
    end
  end
end
