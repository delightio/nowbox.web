require 'bundler'
Bundler.require

class Aji < Thor
  desc "Migrate the database through scripts in db/migrate."
  def migrate
    ActiveRecord::Base.establish_connection(
      YAML.load_file("config/database.yml")[ENV['RACK_ENV'] || 'development'])
    ActiveRecord::Migrator.migrate("db/migrate/")
  end
end
