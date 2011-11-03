module Aji
  module Mixins::Formatters
    module Twitter
      def format message, link
        coda = " #{link} via @nowbox for iPad"
        if (message + coda).length > 140
          message[0..message.length - (3 + coda.length)] << "..." << coda
        else
          message + coda
        end
      end
    end

    module Facebook
      def format message, link
        coda = " #{link} via @nowbox for iPad"
        message + coda
      end
    end
  end
end
