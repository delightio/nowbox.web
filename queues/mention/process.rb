module Aji
  module Queues
    module Mention
      class Process

        @queue = :mention

        def self.perform mention_hash
          # Reinstantiate the mention object.
          mention = Aji::Mention.new mention_hash['mention']

          mention.links.each do |link|
            next unless link.video?
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
      end
    end
  end
end
