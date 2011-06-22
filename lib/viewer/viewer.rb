require 'sinatra/base'

module Aji
  class Viewer < Sinatra::Base
    get '/' do
      "hello world!"
    end
  end
end
