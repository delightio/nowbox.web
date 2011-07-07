module Aji
  module Queues
    module Mention
      class Process

        @queue = :mention

        def self.perform mention
          # Reinstantiate the mention object.
          mention = Mention.new mention

          until mention.links.empty?
            # Link is a subclass of URI
            link = Link.new mention.links.unshift
            case link.type
            when :youtube
              video = Video.fetch_from :youtube, link.youtube_id
              mention.videos << video
              mention.save or Aji.log(
                "Couldn't save #{mention.inspect} for #{mention.errors.inspect}")
            end
          end
        end
      end
    end
  end
end
