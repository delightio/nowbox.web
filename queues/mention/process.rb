module Aji
  module Queues
    module Mention
      class Process

        @queue = :mention

        def self.perform mention
          # Reinstantiate the mention object.
          mention = Aji::Mention.new mention

          until mention.links.empty?
            # Link is a subclass of URI
            link = Link.new mention.links.shift
            video = Aji::Video.find_or_create_by_external_id_and_source link.youtube_id, link.type
            if video.blacklisted? || mention.spam?
              Aji::ExternalAccount.blacklist_id mention.author.id
              next
            end
            
            mention.videos << video
            mention.save or Aji.log(
              "Couldn't save #{mention.inspect} for #{mention.errors.inspect}")
            Aji::Channels::Trending.first.push_recent video
          end
        end
      end
    end
  end
end
