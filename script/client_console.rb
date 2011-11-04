require 'awesome_print'
require 'typhoeus'
require 'faraday'
require 'yajl'
require 'pry'

class ClientConsole
  def initialize
    @domain = "api.nowbox.com"
    @scheme = "http"
    @prefix = ""
    initialize_conn
  end

  def initialize_conn
    @conn = Faraday.new "#{@scheme}://#{@domain}/#{@prefix}"
  end

  def secure_mode!
    @scheme = "https"
    initialize_conn
  end

  def unsecure_mode!
    @scheme = "https"
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
