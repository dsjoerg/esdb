### Introduction

ESDB is the API server for GGTracker.  It is also involved in replay processing.

The other codebases used in GGTracker are:
* https://github.com/dsjoerg/ggtracker <-- the web server and
  HTML/CSS/Javascript for the site
* https://github.com/dsjoerg/ggpyjobs <-- the replay-parsing python
  server, included by ESDB as a git submodule
* https://github.com/dsjoerg/gg <-- little gem for accessing ESDB,
  used by the ggtracker codebase


### Requirements

 * Ruby 1.9+ (get RVM: https://rvm.io/)
 * Bundler 1.2.0+ (gem install bundler --pre)
 * MySQL
 * Memcached
 * Redis
 * Curl
 * imagemagick (http://www.imagemagick.org/)
 * An Amazon S3 account
 
On Mac OSX, you can use homebrew as package manager: http://mxcl.github.com/homebrew/


### Installation and setup

 * Run Bundler (`bundle`)
 * Copy and adjust database configuration (`cp config/database.yml.example config/database.yml`)
 * Create the database esdb needs, and the test database (`mysql -u root` and then `create database esdb_development; create database esdb_test` and then `quit`)
 * Copy S3 configuration and put your AWS credentials and bucket names in it (`cp config/s3.yml.example config/s3.yml`)
 * Copy fog configuration and put your AWS credentials and bucket names in it (`cp config/fog.rb.example config/fog.rb`)
 * Copy and adjust redis configuration (`cp config/redis.yml.example config/redis.yml`)
 * Copy and adjust esdb configuration (`cp config/esdb.yml.example config/esdb.yml`)
 * Copy tokens configuration (`cp config/tokens.yml.example config/tokens.yml`)
 * Run migrations: `bundle exec sequel -m db/migrations -e development config/database.yml`
 * Import the data needed for Spending Skill: `cat db/replays_sq_skill_stat.sql | mysql -u root -D esdb_development`
 * Set up an API identity for the ggtracker web server: `cat db/ggtracker_provider.sql | mysql -u root -D esdb_development`
 * Initialize the ggpyjobs submodule with `rake py:init`
 * Run migrations on test: `bundle exec sequel -m db/migrations -e test config/database.yml`
 * Verify your install with rspec `bundle exec rspec`


### Starting

`foreman start`

Then open your browser to http://localhost:9292/
If you see "Hello World!" then the ESDB server is running, congrats!

Next try opening this URL: http://localhost:9292/api/v1/spending_skill/am/protoss
If you get a bunch of JSON spending skill data, then it really is working.

Next is to try uploading a replay; for that, you'll need to install
the [ggtracker](https://github.com/dsjoerg/ggtracker) webserver on
your dev box.

If you run into any problems, please let me know -- it's probably my
fault and I'll be happy to help you out!


### Testing

bundle exec rspec


### Security

If you see any security problems, please let me know ASAP!  Thx :)
