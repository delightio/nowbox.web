# This file is used by Rack-based servers to start the application.

require './aji'

use HireFireApp::Middleware
run Aji::APP
