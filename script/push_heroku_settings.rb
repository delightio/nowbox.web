require 'yaml'
require 'pry'

CONFIG = YAML.load File.read "./config/settings.yml"

raise ArgumentError unless
  %w[development test production staging].include? ARGV[0]

settings = CONFIG[ARGV[0]].map do |setting, value|
  %Q(#{setting}="#{value}")
end



puts "heroku config:add #{settings.join " "}"

