module Aji
  module Mixins::Formatters
    module Twitter
      def format share
        message = share.message
        link    = share.link
        coda    = " #{link} via @nowbox for iPad"
        if (message + coda).length > 140
          message[0..message.length - (3 + coda.length)] << "..." << coda
        else
          message + coda
        end
      end
    end

    module Facebook
      def format share
        attachment = { "name" => share.video.title,
                       "link" => share.link,
                       "caption" => "I found this great video from #{share.channel.title} channel on NOWBOX",
                       "description" => "Join me on http://nowbox.com/",
                       "picture" => share.video.thumbnail_uri }

        return share.message, attachment
      end
    end
  end
end
