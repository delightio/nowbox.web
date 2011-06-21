source 'http://rubygems.org'

# Application Frameworks and Utilities
gem 'rake'
gem 'thor' # Better command line utility than rake.
gem 'foreman' # Local process monitor.
gem 'grape'
gem 'sinatra', :require => 'sinatra/base'
gem 'thin' # Heroku recommends the Thin web server.
gem 'resque'

# Data persistence and related.
gem 'redis'
gem 'redis-objects', :require => 'redis/objects'
gem 'pg'
gem 'activerecord', ">=3.1.0rc2", :require => 'active_record'

# Literate comments, generating lovely documentation HTML.
gem 'rocco'

# Libraries used by the backend.
gem 'resque-scheduler', '~>2.0.0.d',
  :require => ['resque_scheduler', 'resque/scheduler']
gem 'omniauth'
gem 'youtube_it'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

# Testing gems.
gem 'rack-test'
gem 'rspec'
gem 'factory_girl', :git => 'https://github.com/thoughtbot/factory_girl.git'
