# This file is used by Rack-based servers to start the application.

require "#{File.expand_path(".")}/aji"
run Aji::API
