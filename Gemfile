source "https://rubygems.org"

gem 'unicorn'

gem 'sinatra'
gem 'sinatra-contrib' # for Sinatra::Reloader, etc.

# https://github.com/cyu/rack-cors, see esdb.rb
gem 'rack-cors', :require => 'rack/cors'

# https://github.com/crohr/rack-jsonp
gem 'rack-jsonp', :require => 'rack/jsonp'

gem 'rake'

# Using a fork that removes the strict dependency on Hashie ~> 1.2
# let's pray it doesn't explode and maybe send a pull request upstream?
# (run tests..)
# Note: wait until 2.0 is out of beta, obviously.
gem 'grape', :git => 'https://github.com/ggtracker/grape.git', :ref => '4d94477a94310688790d6c250010dfb531a734cc'
gem 'hashie', :git => 'https://github.com/intridea/hashie.git'

gem 'sequel', :git => 'https://github.com/jeremyevans/sequel.git'
gem 'sequel-factory'

gem 'randexp'

gem 'mysql2'

gem 'tux' # console (ripl)
gem 'hirb' # beautify irb
# gem 'ripltools' # meta gem for multiple ripl extensions, just trying..
gem 'ripl-color_streams'
gem 'ripl-color_error'
gem 'ripl-color_result'

group :test do
  gem 'rspec'

  # Sweatshop for fixtures/generation
  # gem 'dm-sweatshop', :git => "https://github.com/datamapper/dm-sweatshop.git"
  
  # cleans up after us automatically in the test database
  gem 'database_cleaner', :git => 'https://github.com/bmabey/database_cleaner.git'

  # Used this for years - it's a thoughtbot gem. I love these guys.
  # https://github.com/thoughtbot/factory_girl
  gem "factory_girl", "~> 4.0"
  
  # Generates random data :)
  # http://rubydoc.info/github/stympy/faker/master/frames
  gem 'faker'
  
  gem 'simplecov', :require => false
  
  # A web request mocking library that works with Curb::Easy
  # https://github.com/bblimke/webmock
  gem 'webmock'
end

#group :development do
#  gem 'ruby-debug19', :require => 'ruby-debug'
#end

# JSON
# C bindings > Ruby. See https://github.com/brianmario/yajl-ruby
gem 'yajl-ruby'

# Treetop
gem 'treetop'

# See lib/citrus.rb
gem 'citrus'

# our stupid branch of resque 1.23.0, setting the default INTERVAL to 0.1
#
# unfortunately EY's engineyard/bin/resque script makes it well-nigh
#  impossible to pass an env variable through to resque itself.
#
gem 'resque', :git => 'git@github.com:ggtracker/resque.git', :ref => '60f2d6c223b511ce8a52125a8103a375e86f429c'

# Status/metadata for jobs
gem 'resque-status'

# Verbose job stats: https://github.com/alanpeabody/resque-job-stats
gem 'resque-job-stats'

# Round-robining
gem 'resque-dynamic-queues'
gem 'resque-round-robin', :git => 'git@github.com:ggtracker/resque-round-robin.git'
#gem 'resque-round-robin', :path => '/Users/david/Dropbox/Programming/resque-round-robin'


# Evan Weaver, y ur code so fast?
# Note: I'm a huge redis fan as we know, but since memcached is on every EY
# instance anyway and we might not want to juggle redis databases later on..
gem 'memcached'

# Not sure if I want to use JBuilder .. I was very displeased with performance
# on it and pretty much everything else too. So, JBuilder it is, for now.
gem 'jbuilder'

# Curb for curl bindings
gem 'curb'

# Appoxy's AWS gem
# I decided to use it over here because we currently don't need to integrate
# with things like Paperclip here and it seems to be very well maintained.
#
# Docs: http://rubydoc.info/gems/aws/2.5.7/frames
# (Beware: the README links to an apparently outdated version)
gem 'aws'

# Our agoragames/bnet_scraper fork, see ggtracker Gemfile
gem 'bnet_scraper', :git => 'git@github.com:ggtracker/bnet_scraper.git', :ref => 'battlenetify'
# gem 'bnet_scraper', :path => '/Users/mr/dev/ruby/gems/bnet_scraper/'

# Using ActiveSupport >3 for helpers like the Numeric/Time extensions
# to be able to call #hours on a Number for example.
#
# version spec is funky because carrierwave because i18n security problem on 20131204
#
gem 'activesupport', '~> 3.2.8'

# The other really good "attachment processing" gem there is, since Paperclip
# is strictly for Rails.
gem 'carrierwave'

# rubygems can't find 0.1.0 right now.. might be due to rubygems.org issues
gem 'carrierwave-sequel', :require => 'carrierwave/sequel', :git => 'git://github.com/jnicklas/carrierwave-sequel.git'

# Want RMagick for awesome image processing!
# (mini_magick, because I'm afraid of RMagick.. seriously, don't even try
# it'll just piss you off.)
gem 'mini_magick'

# CarrierWave is using Fog and so are millions of others ..I couldn't remember
# this when looking around S3 libraries. It seems a little overkill maybe.
gem 'fog', '~> 1.3.1'

# State Machine.
# Note: I've never had problems with aasm in the past, but it doesn't
# explicitly support Sequel. We could write an adapter pretty quickly and aasm
# still seems more active than state_machine, but.. tight on time here!
# https://github.com/pluginaweek/state_machine
gem 'state_machine'

# This gem is pretty fresh, but what they've implemented pretty solid imho.
# http://artsy.github.com/blog/2012/05/30/restful-api-caching-with-garner/
# What they've done is pretty much exactly what I have done for unlike.net
# manually, with some exceptions. So it's worth a try.
gem 'garner'

gem 'ey_config'

# Or the old and tried new relic (this has been around for years)
gem 'newrelic_rpm'

# Required for rake py:update
gem 'multi_json'

# Foreman is used to launch processes
gem 'foreman'

# http://ruby-statsample.rubyforge.org/
# https://github.com/clbustos/statsample
gem 'statsample'

# garbage commit for re-deploying

# Security advisory! 20131204
gem 'i18n', '>= 0.6.6'
