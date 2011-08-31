source 'http://rubygems.org'

# Application Frameworks and Utilities
gem 'rake'
gem 'thor' # Better command line utility than rake.
gem 'foreman' # Local process monitor.
gem 'grape'
gem 'sinatra', :require => 'sinatra/base'
gem 'thin' # Heroku recommends the Thin web server.
gem 'resque', :require => [ 'resque', 'resque/failure/redis' ]

# Data persistence and related.
gem 'hiredis' # Fast C Interface to Redis.
gem 'redis', :require => [ 'redis/connection/hiredis', 'redis' ]
gem 'redis-objects', :require => 'redis/objects'
gem 'pg'
gem 'activerecord', '~>3.0.9', :require => 'active_record'

# Literate comments, generating lovely documentation HTML.
gem 'rdiscount' # Required for Rocco.

group :development do
  gem 'rocco', '=0.8'
  gem 'awesome_print'
  gem 'pry'
  gem 'pry-doc'
end

# Libraries used by the backend.
gem 'resque-scheduler', '~>2.0.0.d',
  :require => ['resque_scheduler', 'resque/scheduler']
gem 'resque-retry', :require => [ 'resque-retry', 'resque-retry/server' ]
gem 'httparty'
gem 'omniauth'
gem 'youtube_it'
gem 'erubis'
gem 'yajl-ruby'
gem 'twitter'

# Mail related
#gem 'activeresource'
gem 'pony'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

# Testing gems.
group :test do
#  gem 'fakeweb'
#  gem 'vcr'
  gem 'rack-test', :require => 'rack/test'
  gem 'rspec'
  gem 'database_cleaner'
  gem 'cucumber'
  #gem 'capybara' # For viewer app.
  gem 'factory_girl'
  gem 'simplecov'
end
