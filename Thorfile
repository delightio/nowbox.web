require 'bundler'
Bundler.require

class Aji < Thor
  desc "migrate", "Migrate the database through scripts in db/migrate."
  def migrate
    ActiveRecord::Base.establish_connection(
      YAML.load_file("config/database.yml")[ENV['RACK_ENV'] || 'development'])
    ActiveRecord::Migrator.migrate("db/migrate/")
  end

  desc "migration TITLE", "generate a new migration based on the title"
  def migration title
    tmpl = "class #{title.split('_').map(&:capitalize).join('')}"
    tmpl << "< ActiveRecord::Migration\n"
    tmpl << "  def self.up\n    \n  end\n\n"
    tmpl << "  def self.down\n    \n  end\nend"
    `echo '#{tmpl}' > ./db/migrate/#{Time.now.strftime("%Y%m%d%H%M%S")}_#{title}.rb`
  end
end
