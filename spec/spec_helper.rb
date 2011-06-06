ENV["RACK_ENV"] ||= 'test'
require 'rspec'
require 'rack/test'
require_relative '../aji'
require_relative 'factories'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir.glob("#{Aji.root}/spec/support/**/*.rb").each {|r| require_relative r}

module TestMixin
	include Rack::Test::Methods
	def app
		Aji::API
	end
end

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec
  config.include TestMixin
end
