source 'http://rubygems.org'

# Application Frameworks and Utilities
gem 'rake'
gem 'thor' # Better command line utility than rake.
gem 'foreman' # Local process monitor.
gem 'grape', :git => 'git://github.com/intridea/grape.git'
gem 'sinatra', :require => 'sinatra/base'
gem 'thin' # Heroku recommends the Thin web server.
gem 'resque',
  :require => ['resque', 'resque/failure/multiple', 'resque/failure/redis']
gem 'resque-exceptional'
gem 'typhoeus' # Better, Faster HTTP API for Faraday connections

# Data persistence and related.
gem 'hiredis' # Fast C Interface to Redis.
gem 'redis', :require => [ 'redis/connection/hiredis', 'redis' ]
gem 'redis-objects', :require => 'redis/objects'
gem 'pg'
gem 'activerecord', '~>3.0.9', :require => 'active_record'
gem "newrelic_rpm", :git => "git://github.com/newrelic/rpm.git",
  :branch => '3.3.1_dev'

# Literate comments, generating lovely documentation HTML.
gem 'rdiscount' # Required for Rocco.
group :development do
  gem 'rocco', '~>0.8.2'
  gem 'flog'
  gem 'flay'
  gem 'gestalt'
  gem 'blitz'
  gem 'heroku'
end

gem 'awesome_print'
gem 'pry'
gem 'pry-doc'

# Libraries used by the backend.
gem 'resque-scheduler', '~>2.0.0.d',
  :require => ['resque_scheduler', 'resque/scheduler']
gem 'resque-retry', :require => [ 'resque-retry', 'resque-retry/server' ]
gem 'omniauth', '~>0.3.2', :require => 'oa-oauth'
gem 'youtube_it', '~>2.0.0'
gem 'erubis'
gem 'yajl-ruby'
gem 'twitter', '~>1.7.2'
gem 'koala', '~>1.2.0beta'

gem 'tanker'
gem 'will_paginate'

# monitoring
gem 'exceptional'

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
  gem 'vcr', '~>2.0.0.beta1'
  gem 'webmock'
  gem 'rack-test', :require => 'rack/test'
  gem 'rspec'
  gem 'database_cleaner'
  gem 'spinach'
  gem 'factory_girl'
  gem 'simplecov'
end

