### Introduction

ESDB is the API server for GGTracker.  It is also involved in replay processing.

The other codebases used in GGTracker are:
* https://github.com/dsjoerg/ggtracker <-- the web server and HTML/CSS/Javascript
* https://github.com/dsjoerg/ggpyjobs <-- the replay-parsing python server
* https://github.com/dsjoerg/gg <-- little gem for accessing ESDB

It's not ready for public consumption yet.  Don't read this.  Please delete your computer.


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


### Basic installation and updating

 * Run Bundler (`bundle`)
 * Copy and adjust database configuration (`cp config/database.yml.example config/database.yml`)
 * Create the database esdb needs, and the test database (`mysql -u root` and then `create database esdb_development; create database esdb_test` and then `quit`)
 * Copy and adjust S3 configuration (`cp config/s3.yml.example config/s3.yml`)
 * Copy and adjust fog configuration (`cp config/fog.rb.example config/fog.rb`)
 * Copy and adjust redis configuration (`cp config/redis.yml.example config/redis.yml`)
 * Copy and adjust esdb configuration (`cp config/esdb.yml.example config/esdb.yml`)
 * Copy and adjust tokens configuration (`cp config/tokens.yml.example config/tokens.yml`)
 * Run migrations: `bundle exec sequel -m db/migrations -e development config/database.yml`
 * Initialize the ggpyjobs submodule with `rake py:init`
 * Run migrations on test: `bundle exec sequel -m db/migrations -e test config/database.yml`
 * Verify your install with rspec `bundle exec rspec`


### Starting

`foreman start`


### Testing

bundle exec rspec



### OAuth2, Authentication, Client Application, Provider Identification

For ggtracker development you will need a ggtracker Provider with the access token 'development'. If you didn't use one of the dumps including this, make sure to create it:

$ tux
>> Provider.create(:name => 'ggtracker', :access_token => 'development', :callback_url => 'http://localhost:3000/esdb')

Or if you prefer SQL: 
INSERT INTO esdb_providers (name, access_token, callback_url) VALUES ('ggtracker', 'development', 'http://localhost:3000/esdb');


### Security

If you see any security problems, please let me know ASAP!  Thx :)
