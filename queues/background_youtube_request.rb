module Aji
  class Queues::BackgroundYoutubeRequest
    extend Queues::WithDatabaseConnection

    @queue = :background_youtube_request

    def self.perform api_info, api_method, *args
      api = YoutubeAPI.new api_info['uid'], api_info['token'],
        api_info['secret']
      api.send api_method, *args
    rescue AuthenticationError, UploadError => e
      Resque.enqueue_in_front self, api_info, api_method, *args
      api.tracker.close_session! if e.message =~ /too_many_recent_calls/
    end

    # If we're throttled, wait ten seconds, then try again.
    def self.before_perform_check_throttling *args
      if youtube_throttled?
        Resque.enqueue_in_front self, *args
        sleep 10
        raise Resque::Job::DontPerform
      end
    end

    # When we're throttled, this key is set.
    def self.youtube_throttled?
      !Aji.redis.get(YoutubeAPI::THROTTLE_KEY).nil?
    end
  end
end
