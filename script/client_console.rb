require 'awesome_print'
require 'typhoeus'
require 'faraday'
require 'yajl'
require 'pry'

class ClientConsole
  def initialize
    @conn = Faraday.new("http://api.nowbox.com/1") { |f| f.adapter :typhoeus }
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
