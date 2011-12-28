module Aji
  class BackgroundYoutubeAPI
    def initialize uid, token, secret
      @api_info = { :uid => uid, :token => token, :secret => secret }
      @api = YoutubeAPI.new uid, token, secret
    end

    def respond_to? method_name
      @api.respond_to? method_name
    end

    def method_missing method_name, *args, &block
      super unless @api.respond_to? method_name

      call_info = "#{@api_info[:uid]}:#{method_name}:#{args * ","}"
      if post_method? method_name
        Resque.enqueue Queues::BackgroundYoutubeRequest, @api_info, method_name,
          *args
      else
        if @api.tracker.available?
          @api.send method_name, *args, &block
        else
          @api.tracker.add_missed_call call_info

          if array_method? method_name
            []
          else
            nil
          end
        end
      end

    rescue AuthenticationError, UploadError => e
      @api.tracker.add_missed_call call_info

      reason = "#{call_info} => #{e.inspect}"
      @api.tracker.close_session!(reason) if e.message =~ /too_many_recent_calls/
    end

    def post_method? method_name
      [:subscribe_to, :unsubscribe_from, :add_to_favorites, :add_to_watch_later,
       :remove_from_favorites, :remove_from_watch_later].include? method_name
    end
    private :post_method?

    def array_method? method_name
      [:subscriptions, :favorite_videos, :uploaded_videos,
       :watch_later_videos].include? method_name
    end
    private :array_method?
  end
end

