Core Dump:
==========

*A Journal of Engineering Notes*

Where Aji is Now
----------------

### Architecture ###

Right now the Aji application is laid out in the somewhat standard Ruby
convention. It's very similar to the layout of a Ruby on Rails application but
dispenses with the (pointless) `app` directory and keeps the `models` and
`controllers` directories in the project root. We bundle with the `--binstubs`
option for two reasons.  First because `bin/rspec` is slightly less typing than
`bundle exec rspec` and second, because the latter actually has to load Ruby and
RubyGems twice, once to execute the command, and once when the application code
is run. Using the binstubs eliminates this problem which gets worse the more
gems you have on your system. So most everything in the `bin` directory is a
quicklink to a bundled gem binary. The exception being `bin/aji` which is the
command line tool for the Aji application. It is built using Wycat's Thor, but
due to a smeg-up on my part, constant collisions mean that the Aji binary cannot
run in the same interpreter as the application unless we change it's name. See
__Appendinx A__ for a complete explanation of the file hierarchy.

The bulk of the Aji codebase is centered around a JSON CRUD (Create, Retrieve,
Update, Destroy) API powered by Grape. It isn't yet a proper REST API due to the
lack of [HATEOAS (Hypermedia as the Engine of Application State)][HATEOAS] The
API application is entirely model-driven although it is not MVC. The sole
responsibility of the controllers is validating parameters and creating or
retrieving resources. The `Aji::API` class is a `Grape::API`, OmniAuth callbacks
are kept in `controllers/auth_controller.rb` A Sinatra app which is also
responsible for security token provisioning. The [nowbox.com](http://nowbox.com)
homepage is served from the Sinatra application `Aji::Viewer` located in
`lib/viewer`. It could probably do with a rename and might even become a
completely separate project. See the sections *Client-Heavy Application Layer*
and *Static-Server Share Page* in __Where I Think It's Going__.

### Feature set ###

Right now the Aji application we have a rather comprehensive set of tests on the
following resources:

- Accounts: *User accounts on other services, currently Facebook, Twitter, and
  YouTube, from which we push and pull information.*

- Channels: *The primary video-collecting abstraction and a core metaphor in the
  NOWBOX product.* Currently we can make channels from any collection of
  accounts or a set of keywords on YouTube. We also use Channels as the
  implementation behind a user's watched, favorite, and queued videos. This will
  make it simple to let users share these channels or make them public in the
  future.

- Shares: *A share resource is created any time a user favorites a video and
  posts it to Facebook or Twitter.*

- Events: *Every action a user takes with respect to a video and/or channel
  produces an event.* The event resource is really ugly to me right now and is
  the biggest architectural holdover from the previous incarnation of NOWBOX
  (Nowmov) Events are ***critical*** to the future of the application and we'll
  rely on them for everything from video recommendation to revenue generation.
  However, they act as an RPC call on the User class right now and bottleneck
  darn near everything. For more on events in the future see the section in
  __Where I Think It's Going__ titled _Consumer, B2B, and Internal Uses for
  Events_.

- Identities: *The Identity model is essential a named join table between a user
  and some accounts.*
  It represents a potentially large premature abstraction on my part but at the
  time it was written I felt as though it's projected use case was right around
  the corner. Identity is meant to act as a unification between a user and their
  Identity through various services (Twitter, Facebook, Youtube, Vimeo, NOWBOX).
  It's not limited to people but was meant to include brand identities such as
  Coca-Cola.

- Users: *Our friends, loved ones, and bread and butter. These are the people
  who use our apps.*

- Videos: *Our app plays videos, this is the resource that represents one.*

- Test comprehensiveness
- Primary candidates for refactoring
- Secondary candidates for refactoring
- Tooling past, present, and maintenance
I find
  them easier verification of feature completeness than trying to do the same
thing using only RSpec and Rack Test. I believe Thomas finds them a little too
abstract and in the future something like [Steak](https://github.com/cavalle/steak)
might be preferred. Although Capybara really sucks for API-driven work.

---

- Where I think it's going
  - ROFLScaling
  - presenter pattern
  - Sinatra
  - becoming realtime
  - Share page => Client-heavy OR Server-static.
  - Consumer, B2B, and Internal Uses for Events

- Pitfalls in the current implementation
  - events
  - idenitities
  - accounts <-> users
  - 

- Solutions to as-yet unexhibited problems

- Maintenance, Bolt-ons, and Totally New Features

---

Appendices
==========

Appendix A: A Complete Explanation of the Aji Project Directory
---------------------------------------------------------------

- `bin/`: Bundler binstubs and `aji` command-line tool.
- `config/`: All of the runtime configuration details for the app and a
  `config.rb` script which initializes them as detailed [here][blog1]. Ruby
  est practice states that we shouldn't store our actual settings in the repo in
  case it is ever open sourced. So we use FILENAME.template.yml and store that.
- `controllers/`: Controllers which are the meat of the Aji::API class.
  Controllers are all named `#{resource}_controller.rb` where resource is the
  name of the CRUD resource.
- `coverage/`: Code coverage report generated by SimpleCov.
- `db/migrate`: All our database migrations.
- `docs/`: API documentation generated by [Rocco][] essential markdown in
  comments.
- `features/`: I recently started writing acceptance tests for our API.
- `helpers/`: Application helpers, mainly facilitating common controller
  patterns. These have recently been moved into a module so they can be more
  easily shared with auxiliary Sinatra applications.
- `lib/`: Like most apps, lib is the bitbucket for stuff that doesn't belong
  anywhere obvious.
- `lib/mailer`: The mailer project Fahd was working on before he left. I've not
  had my hands in this too much as it was shelved after his departure. I think
  this can be safely removed.
- `lib/mixins`: Shared behavior for our models.
- `lib/patches`: Every company has some skeletons in the closet. This is our
  closet. Monkey patches to standard libraries and gems go here. More on them in
  the pitfalls section.
- `lib/viewer`: This is the now poorly named Sinatra app that houses our main
  web site as well as the public share page dynamic content.
- `models/`: If it's a class we wrote, named after something in our app, it's a
  model. Models aren't only ActiveRecord classes. Any class representing a
resource or process specific to our product really goes here.
- `queues/`: Our Resque queues.
- `script/`: One-time run scripts to do all sorts of things.
- `spec/`: RSpec tests. Our models have pretty decent coverage although many of
  the tests are not as isolated as they can or should be.
- Top-level files
  - `aji.rb`: Serves as the main initializer for the application. Require it to
    get everything. I sometimes wonder if it isn't better to make this tiny and
    split all the real work into an `init.rb` but I don't see the point yet.
  - `app.rb`: The mountable Rack application created by composing the API,
    Viewer, Resque::Server, Documentation server, and OmniAuth middleware. This
    used to be directly in `config.ru` but I had to move it so I could use the
    whole thing during tests.
  - `config.ru`: Our Rackup config. Now just uses `Aji::APP`.
- The ALL_CAPS.md family
  - `README.md`: the application README file. It details what is needed to get the
    application up and running.
  - `BALANCE_SHEET.md`: My previous attempt at keeping a log of technical waste
    in the system and coming up with a plan to fix it. Needless to say it was
    relatively unsuccessful so I've removed it and rolled the information up
    into this journal.
  - `CORE_DUMP.md`: This file.

Appendix B: Developer Resources
-------------------------------
- Books
- IRC
- Ruby Meetups

[blog1]: http://blog.nuclearsandwich.com/blog/2011/06/25/a-sane-configuration-setup-for-rack-applications-on-heroku/
[Rocco]: http://rtomayko.github.com/rocco/
[HATEOAS]: https://en.wikipedia.org/wiki/HATEOAS

