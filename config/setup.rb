if File.exists? "config/settings.yml"
  Aji.conf.merge!(YAML.load_file("config/settings.yml")[Aji::RACK_ENV])
  Aji.conf['RESQUE_SCHEDULE'] = YAML.load_file("config/resque_schedule.yml")
else
  Aji.conf.merge!(ENV)
end

db = URI Aji.conf['DATABASE_URL']
redis = URI Aji.conf['REDISTOGO_URL']

# Parse Postgres connection settings.
Aji.conf['DATABASE'] = {
  :adapter => "#{db.scheme}ql",
  :host => db.host,
  :port => db.port,
  :database => db.path[1..-1],
  :username => db.user,
  :password => db.password
}

# Parse Redis connection settings.
Aji.conf['REDIS'] = {
  :host => redis.host,
  :port => redis.port,
  :password => redis.password,
  :db => redis.path[1..-1]
}

# Parse Resque Schedule Yaml.
if Aji.conf['RESQUE_SCHEDULE'].class == String
  Aji.conf['RESQUE_SCHEDULE'] = YAML.load Aji.conf['RESQUE_SCHEDULE']
end

Aji.conf.freeze
