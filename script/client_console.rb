require 'awesome_print'
require 'typhoeus'
require 'faraday'
require 'yajl'
require 'pry'

class ClientConsole

  CLIENT_SECRET =
    "j3sBP0aRG8neHoWe7MtLDp6aPQYQUQjhtIh9cVFjmiQPvdYFpWi2PbxVZrpwa7t1YrMzWtppR1crSyNV3w"

  def initialize
    @domain = "api.nowbox.com"
    @scheme = "http"
    @prefix = ""
    @headers = {}
    initialize_conn
  end

  def initialize_conn
    @conn = Faraday.new "#{@scheme}://#{@domain}/#{@prefix}",
      :headers => @headers
  end

  def get_token user_id
    secure_mode! do
      r = parse_response @conn.post '/auth/request_token', :user_id => user_id,
        :secret => CLIENT_SECRET
      if r[0] == 200
        @token = r[2]['token']
      else
        @token = nil
      end
    end
  end

  def authenticate! user_id
    get_token user_id
    if @token
      @headers['X-NB-AuthToken'] = @token
      initialize_conn
    end
  end


  def deauthenticate!
    @headers.delete 'X-NB-AuthToken'
    @token = nil
    initialize_conn
  end

  def secure_mode!
    @scheme = "https"
    initialize_conn
    if block_given?
      yield
      @scheme = "http"
      initialize_conn
    end
  end

  def unsecure_mode!
    @scheme = "https"
    initialize_conn
  end

  def staging!
    @domain = "api.staging.nowbox.com"
    initialize_conn
  end

  def production!
    @domain = "api.nowbox.com"
    initialize_conn
  end

  def use_prefix p
    @prefix = p
    initialize_conn
  end

  def add_prefix p
    @prefix << p
    initialize_conn
  end

  def clear_prefix
    @prefix = ""
    initialize_conn
  end

  def parse_response resp
    [ resp.status,
      resp.headers,
      Yajl::Parser.parse(resp.body),
    ]
  rescue
    [ resp.status, resp.body, resp.headers ]
  end

  def method_missing sym, *args, &block
    super(sym, *args, &block) unless sym =~ /^(?:get|put|post|delete)$/

    parse_response(@conn.send sym, *args)
  end
end

ClientConsole.new.pry
