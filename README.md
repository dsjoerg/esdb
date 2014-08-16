### Introduction

WTF is this?

It's not ready for public consumption yet.  Don't read this.  Please delete your computer.


### Requirements

 * Ruby 1.9+ (get RVM: https://rvm.io/)
 * Bundler 1.2.0+ (gem install bundler --pre)
 * MySQL
 * Memcached
 * Redis
 * Curl
 * imagemagick (http://www.imagemagick.org/)
 * engineyard gem 2.0+ for deployment (the EY web interface will not work right now)
 * An Amazon S3 account
 
On Mac OSX, you can use homebrew as package manager: http://mxcl.github.com/homebrew/


### Basic installation and updating

The first steps that should be done when checking out a fresh copy:

 * Run Bundler (`bundle`)
 * Copy and adjust database configuration (`cp config/database.yml.example config/database.yml`, make sure you use the mysql2 adapter)
 * Copy and adjust S3 configuration (`cp config/s3.yml.example config/s3.yml`)
 * Copy and adjust fog configuration (`cp config/fog.rb.example config/fog.rb`)
 * Copy and adjust redis configuration (`cp config/redis.yml.example config/redis.yml`)
 * Copy and adjust esdb configuration (`cp config/esdb.yml.example config/esdb.yml`)
 * Run migrations: `bundle exec sequel -m db/migrations -e development config/database.yml`
 * Initialize the ggpyjobs submodule with `rake py:init`
 * Run migrations on test: `bundle exec sequel -m db/migrations -e test config/database.yml`
 * Verify your install with rspec `bundle exec rspec`
 * Add a provider key for development, see the OAuth section below.

Whenever you pull in changes to Gemfile* or db/migrations, you should run Bundler or migrations, then check integrity by running specs.


### Starting

`foreman start`


### Testing

bundle exec rspec

To get SQL queries executed into STDOUT when running rspec, use the environment variable DEBUG: `DEBUG=1 bundle exec rspec`



### ggpyjobs

Use our rake tasks to init or update ggpyjobs:

 * `rake py:init` will initialize the submodule at it's specified ref
 * `rake py:update` will pull in HEAD

Both rake tasks will attempt to update via pip from requirements.txt. Also see vendor/ggpyjobs/README.md



### OAuth2, Authentication, Client Application, Provider Identification

For ggtracker development you will need a ggtracker Provider with the access token 'development'. If you didn't use one of the dumps including this, make sure to create it:

$ tux
>> Provider.create(:name => 'ggtracker', :access_token => 'development', :callback_url => 'http://localhost:3000/esdb')

Or if you prefer SQL: 
INSERT INTO esdb_providers (name, access_token, callback_url) VALUES ('ggtracker', 'development', 'http://localhost:3000/esdb');

Notes: as of 201209 there were a bunch of starting, abandoned, WIP/POC libraries and approaches to implementing OAuth2, see https://github.com/intridea/grape/issues/19 for some discussion for Grape on this.

We don't need a full implementation currently, so what we have instead is a setup that is prepared to be used with one, which simply identifies a Provider based on a token and that's it. I'll keep this updated once we've decided whether we even open up the esdb API to the public (and therefore require rate limiting, authorization, etc.)

As of now, esdb will only try to identify a Provider if the access_token param is present (and bail if it is invalid.)


### Security

If you see any security problems, please let me know ASAP!  Thx :)
