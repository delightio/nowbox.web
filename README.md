Aji
===

We all know what Aji is, what we may not know is how it's structured, what it
makes use of, and what conventions it establishes in order to be totally awesome
and generally successful.

Quick Tricks and Tips
---------------------
- Run local console: `bin/aji console` or `bin/aji c`
- Run remote console: `heroku run console`
- Run spec tests: `bin/aji spec` or `bin/aji sp`
- Run local web server: `bin/foreman start web`
- Run local full stack: `bin/foreman start -c resque=3`
- Get Heroku process status: `heroku ps`
- Change Heroku worker count: `heroku scale web=x resque=y`

Technology Stack
----------------
For an exhaustive list it is probably easiest to inspect the `Gemfile`. Here's
an overview though.

### Development
- Git for source code management.
- GitHub for repository hosting.
- LightHouse for project and ticket management.
- Bundler for gem dependency mangement and resolution.
- Thor for command line interaction with the application and environment.
- Rake for some legacy interaction with Resque.
- Rspec for unit and integration testing.
- Factory Girl for object mocking.
- Rocco for API and internal documentation generation.
- Foreman for process management during development.

### Application
- Ruby, naturally
- Grape for the JSON API.
- Sinatra for the web share view and static site portions.
- OmniAuth for external service authentication.
- OAuth planned use for user authentication.
- PostgreSQL 9 for relational data persistence.
- Redis for set data persistence, message passing, and caching.
- Resque for background job queueing and management.
- ActiveRecord for Object-Relational Mapping.
- Thin for better-than-WEBrick http performance.

### Production
- Lumberjack will be used for logging.
- Heroku for easy application management, hosting, and deployment.
- Heroku also provides our Postgres database.
- RedisToGo provides our Redis database Tools.
- NewRelic will provide realtime monitoring and notification.

Application Structure
---------------------
Aji is a Rack application consisting of two major portions, the API, and the
web viewer. Both are lightweight Rack applications powered by the Grape and
Sinatra microframeworks respectively. The main application is the API and the
viewer is kept under `lib/viewer` but may be separated at a later date.

We use MVC pattern for both applications though the API renders and serves JSON
directly from the controller so the view layer only applies to the web share
app. Logic should all be contained in the models and the controllers should
serve only as the API defintion and accessor to that logic. (Fat models, skinny
controllers).

Installation and Setup
----------------------

1. The first thing to do is ensure you have RVM with Ruby 1.9.2 or later,
PostgreSQL 9.x, and Redis 2.2 or later installed on your development system.
The manner in which you install these things is left to you. Create postgres
databases for both development and testing environments making a note of the
database names for each. `aji_dev` and `aji_test` are recommended.

2. Next install the heroku command line tool and Bundler. I recommend using rvm's
global gemset for these as they will be useful across any number of projects.
`gem install heroku bundler`

3. Follow [this article][1] to get Heroku set up. Make a note of where you clone
the application and change to that directory.

4. Run `bundle install`, this will pull all necessary rubygems and install them
cleanly.

5. Open `config/settings.template.yml` in your preferred editor and customize
to suit your setup. Save the result as `config/settings.yml`. DO NOT overwrite
the template file.

6. Run `bin/aji spec` to run tests and make sure everything is hunky dory.

7. Run `bin/aji console` to access the development console for the Aji
enviornment. `include Aji` to get direct access to inner classes such as models.

8. Run `foreman start` to run the entire application including background
workers and scheduler.

9. Hack. Commit. Push. Conquer.

[1]:http://devcenter.heroku.com/articles/collab
