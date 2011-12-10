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

      if post_method?
        Resque.enqueue Queues::BackgroundYoutubeRequest, @api_info, method_name,
          *args
      else
        return nil if @api.tracker.exceeded_limit?
        @api.send method_name, *args, &block
      end

    rescue UploadError => e
      api.tracker.close_session! if e.message =~ /too_many_recent_calls/
    end

    def post_method? method_name
      [:subscribe_to, :unsubscribe_from, :add_to_favorites, :add_to_watch_later,
       :remove_from_favorites, :remove_from_watch_later].include? method_name
    end
    private :post_method?
  end
end

