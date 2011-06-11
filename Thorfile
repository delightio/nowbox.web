require 'bundler'
Bundler.require

class Aji < Thor

  map "c" => :console, "s" => :server, "sp" => :spec
  desc "migrate", "Migrate the database through scripts in db/migrate."
  def migrate
    ActiveRecord::Base.establish_connection(
      YAML.load_file("config/database.yml")[ENV['RACK_ENV'] || 'development'])
    ActiveRecord::Migrator.migrate("db/migrate/")
  end

  desc "migration TITLE", "generate a new migration based on the title"
  def migration title
    filename = "#{Time.now.strftime("%Y%m%d%H%M%S")}_#{title}.rb"
    tmpl = "class #{title.split('_').map(&:capitalize).join('')}"
    tmpl << " < ActiveRecord::Migration\n"
    tmpl << "  def self.up\n\n  end\n\n"
    tmpl << "  def self.down\n\n  end\nend"
    `echo '#{tmpl}' > ./db/migrate/#{filename}`
  end

  desc "console", "An application console for Aji"
  def console
    # Shell out to an irb session with the local environment loaded.
    irb_command = "irb -r #{Dir.pwd}/aji.rb"
    exec irb_command
  end

  desc "spec", "Run application spec tests"
  def spec
    exec "bin/rspec spec"
  end

  desc "server", "Run Aji webserver"
  def server env="development"
    exec "bin/rackup -E #{env}"
  end
  
  desc "docs", "generate Rocco documentation"
  def docs
    exec "bin/rocco -o docs/ aji.rb controllers/*"
  end
  
  desc "docs_clean", "Remove all files from docs/ directory"
  def docs_clean
    exec "rm -r docs/*"
  end
  
end
