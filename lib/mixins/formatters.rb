module Aji
  module Mixins::Formatters
    module Twitter
      def format share
        message = share.message
        link    = share.link
        coda    = " #{link} via @nowbox"
        if (message + coda).length > 140
          message[0..message.length - (3 + coda.length)] << "..." << coda
        else
          message + coda
        end
      end
    end

    module Facebook
      def format share
        name = if share.publisher.realname
                 "#{share.publisher.realname}"
               else
                 "I"
               end
        attachment = { "name" => share.video.title,
                       "link" => share.link,
                       "caption" => "#{name} shared a video from the #{share.channel.title} channel on NOWBOX.",
                       "description" => "Download the free iPad app on http://nowbox.com/",
                       "picture" => share.video.thumbnail_uri }

        return share.message, attachment
      end
    end
  end
end
