module Aji
  module Queues
    module Mention
      class Process
        extend WithDatabaseConnection

        @queue = :mention

        def self.perform source, data, channel_id
          channel = Channel.find channel_id
          mention = Parsers[source].parse data do |mention_hash|
            MentionProcessor.video_filters[source].call mention_hash
          end

          unless mention.nil?
            processor = MentionProcessor.new mention, channel
            processor.perform

            if processor.failed?
              Aji.log "Processing of Mention[#{processor.mention.id}], #{processor.mention.body}. failed due to " +
                processor.errors
            end
          end
        end
      end
    end
  end
end

