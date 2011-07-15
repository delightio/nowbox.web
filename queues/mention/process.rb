module Aji
  module Queues
    module Mention
      class Process

        @queue = :mention

        def self.perform mention
          # Reinstantiate the mention object.
          mention = Aji::Mention.new mention

          mention.links.each do |link|
            video = Aji::Video.find_or_create_by_external_id_and_source(
              link.external_id, link.type)
            next if video.blacklisted?
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
