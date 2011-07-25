# here we go
# TODO: Replace with bundler deps.
require 'oauth/client/em_http' # any reason this is _ instead of - ? *sigh*
require_relative 'twoauth'

stream_url = 'http://stream.twitter.com/1/statuses/filter.json?track=http'
stream_uri = URI.parse stream_url

$delay_count = 1

def handle_error h
  stop_p = false
  if ((h.response_header.status > 200) rescue true)
    delay = 10
    sleep_time = [delay * $delay_count, 240].min
    sleep sleep_time
    $delay_count += 1
  else
    raise RuntimeError, h
  end
end

# see: http://adam.heroku.com/past/2010/3/19/consuming_the_twitter_streaming_api/

print_per_statuses = 5000

count = 0
last_tweet_count = 0
start = Time.now
bytes = 0

exception_recovery_time = 60 * 5 # five minutes
http_timeout = 90 # seconds

class Dummy 
  attr_accessor :use_ssl, :address, :port
end

Aji.log "starting up read_stream ..."

loop do
  begin
    EventMachine.run do
      access_token = Twoauth.get_nm_token

      http = EventMachine::HttpRequest.new(stream_url).get(:timeout => http_timeout)

      # don't ask.  the oauth! mixin method requires an object that
      # answers to :use_ssl, :address (MEANING HOST!), and :port.  I
      # should clone this and fix. ~ jfb
      dummy = Dummy.new(:use_ssl => false, :address => "stream.twitter.com", :port => 80)
      http.oauth!(dummy,
                  access_token.consumer,
                  access_token)

      http.errback { |o| handle_error o } # set this for exceptional cases
      buffer = ""

      http.stream do |chunk|
        # see http://dev.twitter.com/pages/streaming_api_concepts#connecting
        if http.response_header.status != 200
          handle_error http
        else
          $delay_count = 1
        end

        buffer += chunk
        while line = buffer.slice!(/.+\r?\n/)
          begin
            tweet = Yajl::Parser.parse(line, :symbolize_keys => true)
          rescue => e
            raise RuntimeError, "#{line} #{buffer}"
          end
          # tweets are delivered as hashes
          if tweet[:limit]
            last_tweet_count = tweet.dig(:limit, :track).to_i - last_tweet_count
            next
          end
          if !tweet[:text]
            Aji.log :error, "#{tweet.inspect}"
            next
          end
          # Skipping non-english tweets for now.
          next if tweet.dig(:user, :lang) != "en"
          next if Resque.size('process_links') > 100000
          Resque.enqueue Queues::Mention::Parse, "twitter", line
          count += 1
          bytes += line.size

          if (count % print_per_statuses) == 0
            finish = Time.now
            duration = finish - start
            kbytes_s  = (bytes.to_f / 1024.0) / duration.to_f
            status_s = count.to_f / duration.to_f
            missed_s = last_tweet_count / duration.to_f
            Aji.log "read %d statuses (missed %6d statuses) in %6.02f seconds: %6.02f Kb/sec, %6.02f statuses/sec, %8.02f misses/sec" % [count, last_tweet_count, duration, kbytes_s, status_s, missed_s]
            count = 0
            bytes = 0
            last_tweet_count = 0
            start = finish
          end
        end
      end
    end
  rescue => e
    Aji.log :error, "read_stream encountered an exception: #{e}, stopping and sleeping #{exception_recovery_time} seconds\n#{e.backtrace.join("\n")}"
    begin
      EventMachine.stop
    rescue => e
      # pass
    end
    sleep exception_recovery_time
  end
end
