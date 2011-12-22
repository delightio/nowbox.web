Core Dump:
==========

*A Journal of Engineering Notes*

Preamble
--------

Hi, my name is Steven! Chances are if you're reading this, you're either Thomas.
(Hi Thomas!) or fine lady or gentleman they've found to replace me. If at any
time reading through my code or this document you feel I owe you a drink. My
email address is <steven@nuclearsandwich.com>, let me know and I'll buy you one,
chances are I owe it you. I've striven to create a quality application capable
of growing to millions of users and yet allow it to be easily extensible.


Where Aji is Now
================

Architecture
------------

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
retrieving resources. The OmniAuth callbacks are kept in
`controllers/auth_controller.rb` A Sinatra app which is also responsible for
security token provisioning. The [nowbox.com](http://nowbox.com) homepage is
served from the Sinatra application `Aji::Viewer` located in `lib/viewer`. It
could probably do with a rename and might even become a completely separate
project. See the sections *Client-Heavy Application Layer* and *Static-Server
Share Page* in __Where I Think It's Going__.

Feature Set
-----------

Right now the Aji application has a rather comprehensive set of tests on the
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

Test Comprehensiveness
----------------------

Our testing is pretty decent but not ideal. We have a number of tests which only
test the "happy path", most notably `spec/models/mention_processor_spec.rb`. We
also have a bit of a schism happening right now, I was beginning a transition
from doing controller tests integration style in RSpec to doing them Acceptance
style in Spinach. I'd done tests for Youtube Syncing, Authentication and
Authorization, and the Users API. The Users API is double covered between RSpec
and Spinach. I think Spinach completely decouples our controller tests from our
implementation details and does more to prevent [poor acceptance
testing][blog2].I find them easier verification of feature completeness than
trying to do the same thing using only RSpec and Rack Test. I believe Thomas
finds them a little too abstract and in the future something like
[Steak][] might be preferred. Although Capybara really sucks for API-driven
work.

Some Targets for Refactoring
----------------------------

- `Channel::FacebookStream` and `Channel::TwitterStream`  
When I wrote these two classes, I was in a hurry. The feature they implement has
been promised as just around the corner for weeks and I was anxious to get it
out. I was also uncertain whether I was writing the code so similarly because I
was writing them in parallel or if it was because there's no difference between
the two other than the type of account that owns them. At this point I'm pretty
certain they ought to be merged into one `Channel::SocialStream` or something.

- `Event`, `Share`, and hooks  
I spent a good amount of time thinking ahead for this one. When the time came to
implement YouTube account login, which at the time of writing is the most
complete of our external account integrations, I didn't want to hack something
up the way I hacked apart Twitter and Facebook accounts. The hook system is a
way to delegate secondary actions from User actions to any accounts associated
with that user. It makes use of the Identity model. Basically, a hook on an
action is called and the identity walks through associated accounts and calls a
method if it's implemented on that account. This allows users signed in with
youtube to push video and channel actions without requiring any knowledge, or
even presence/absence knowledge, of our Youtube interface. I would like to see
this system used to do as much of the live interaction between accounts and
users. I think sharing is probably a touch too complicated for the hook service,
but certainly a "frictionless" Facebook or Twitter sharing could be enabled
through this interface.

- `TwitterAPI/FacebookAPI#video_mentions_in_feed`  
This method just looks ugly as sin. It looks like the kind of nonsense I was
writing in my first Java class...I just can't figure out an idiomatic Ruby way
to do algorithmic stuff like this. If you find something that looks good, I'd
love to see the solution.

- Unmangle the User<->Accounts relationship.  

Tooling Past, Tooling Present, and Maintaining Tools
----------------------------------------------------

I feel like the tooling on Aji is a lot more sensible and deliberate than the
tooling decisions made for Nowmov. Then again, that could simply be because I
chose many of them. One of the things I'm completely proud of is the fact that
only *one* of the gems in our Gemfile references a git checkout rather than a
release, and that's only to fix a dependency conflict. Git gems create problems
when someone doesn't use `Gemfile.lock` or `bundle update` properly. An eye
should be kept on Grape and someone within the company should definitely be on
the [Grape Mailing List][GrapeML]. Grape has a major internal refactoring
underway and the next released version of the Gem is going to change things
massively. It's going to make Grape faster, better, and easier to use, but it's
also (if left on its own) going to break my hacked up NewRelic instrumentation
for Grape. I'm spending my January 2012 doing open source development and as
part of that want to work with the Grape and RPM contrib folks on getting a good
Instrumentation solution that works Out of the Box on the next release of Grape.

Additionally, there's the distinct possibility that a lack of courageous
developers might push you to port the app back to Sinatra. I couldn't
necessarily blame you, and the port wouldn't be that hard. But if you do, be
aware that you'll want a separate Sinatra application per controller, and you'll
need to do the url versioning and routing in `app.rb`.

### An Example ###
```ruby
# shares_controller_grape.rb
class Aji::API
  version '1'
  resource :shares do
    get "/:share_id" do
      Share.find params[:share_id]
    end
  end
end

# app.rb
map "http://api.#{Aji.conf['TLD']}/" do
  use Rack::Cache,
    :verbose => true,
    :metastore   => "memcached://localhost:11211/api/meta",
    :entitystore => "memcached://localhost:11211/api/body"
    run Aji::API
  end
end
```

Would become

```ruby
class Aji::SharesController
  get "/:share_id" do
    json_encode(Share.find params[:share_id])
  end
end

# app.rb
map "http://api.#{Aji.conf['TLD']}/1/shares" do
  use Rack::Cache,
    :verbose => true,
    :metastore   => "memcached://localhost:11211/api/meta",
    :entitystore => "memcached://localhost:11211/api/body"
  run Aji::SharesController
end
# ... other controllers.
```

Other than the currently git-ed Grape, I highly recommend you join the lists for
each and every gem we rely on. YouTubeIt, Pry, RSpec, VCR, Sinatra,
Rails/ActiveRecord. We should have a representative of the company on each of
these mailing lists. Hitherto it has been me. I am naturally passing that torch
along with everything else. The reason you should be there is to keep an eye on
changes. We can prevent changes that hurt us or minimize the damage by knowing
early.

I'm also worried that YouTubeIt is a completely dead project. I'm going to try
and merge my monkey-patched changes into the main source and submit a pull
request but I'm not sure if anyone is there to listen.


Where I Think It's Going
========================
- ROFLScaling
- presenter pattern
- Sinatra
- becoming realtime
- Client-heavy Application Layers
- Static-Server Share Pages
- Consumer, B2B, and Internal Uses for Events

- Maintenance, Bolt-ons, and Totally New Features
The nice thing about building servers for mobile applications is that we get to
go Service-Oriented Architecture by default. It's my opinion we should embrace
that and no matter where the product goes, attempt to maintain a collection of
loosely coupled applications whose only relation is the domain they model. While
it should be easy to add features to the API and Viewer applications, that
doesn't necessarily mean you should. Think hard about what aspect of the product
your building, then determine if it fits obviously as an extension of what we
have or if it's something new.



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

Appendix B: Noteworthy Libraries to Keep on your Radar
------------------------------------------------------

- [Sinatra][]
- [Padrino][]
- [Sinatra::Synchrony][SS]
- [Rack::Test::REST][RTR]
- [RABL][]
- [Draper][]

Appendix C: Developer Resources
-------------------------------
- Books
- IRC
- Ruby Meetups

[blog1]: http://blog.nuclearsandwich.com/blog/2011/06/25/a-sane-configuration-setup-for-rack-applications-on-heroku/
[Rocco]: http://rtomayko.github.com/rocco/
[HATEOAS]: https://en.wikipedia.org/wiki/HATEOAS
[blog2]: http://aslakhellesoy.com/post/11055981222/the-training-wheels-came-off
[Steak]: https://github.com/cavalle/steak
[GrapeML]: https://groups.google.com/forum/?hl=en#!forum/ruby-grape
