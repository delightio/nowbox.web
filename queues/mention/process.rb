module Aji
  module Queues
    module Mention
      class Process

        @queue = :mention

        def self.perform source, data
          start = Time.now
          mention = self.parse source, data

          # TODO: Refactor into Mention#{unsuitable,unfit,invalid}
          if mention.nil? || mention.author.blacklisted? || !mention.has_links?
            Aji.log "Mention #{mention.inspect} was not suitable for proccessing."
            return
          end

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
          Aji.log "Processing Mention#{mention.id} took #{Time.now - start} seconds."
        end

        # Handles incoming parse requests from various social feeds. If the mention
        # contains a valid http(s) link it will be enqueued for processing. At this
        # time there exists no efficient way to filter out non-video links as link
        # expansion will be necessary in many cases (fskcing overzealos t.co use by
        # Twitter)
        def self.parse source, data
          start = Time.now
          case source
          when 'twitter'
            mention = Parsers::Tweet.parse data
          else
            Aji.log :WARN, "Attempt to process #{data} from #{source}. Unknown"
            # TODO: Add benign return value here.
          end
          Aji.log "Parse of #{mention.inspect} took #{Time.now - start} seconds." if false
          mention
        end
      end
    end
  end
end
