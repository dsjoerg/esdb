ENV['RACK_ENV'] = 'test'

require File.join(File.dirname(__FILE__), '..', 'esdb.rb')

# auto_migrate! will fail like this:
# https://github.com/datamapper/dm-rails/issues/35
# TODO: find solution, comment on the issue!
# but for now, let's just do something like @eltiare suggested

# adapter = DataMapper.repository.adapter
# adapter.execute("DROP DATABASE `#{adapter.options['database']}`")
# adapter.execute("CREATE DATABASE `#{adapter.options['database']}`")
# adapter.execute("USE `#{adapter.options['database']}`;")
# DataMapper.auto_upgrade!

# TODO: parts of the specs are still using sequel-factory, flip them over
# to factory_girl.

require 'rack/test'

require 'database_cleaner'
DatabaseCleaner.strategy = [:truncation, except: [:schema_info]]

RSpec.configure do |conf|
  conf.include Rack::Test::Methods

  conf.before(:all) do
    DatabaseCleaner.clean
  end
end

# Factories, duh!
FactoryGirl.find_definitions

# Mocking web requests
require 'webmock/rspec'

# Kill output of binary bodies.. good god, why?
# https://github.com/bblimke/webmock/blob/master/lib/webmock/errors.rb
# https://github.com/bblimke/webmock/blob/master/lib/webmock/request_signature.rb
class WebMock::RequestSignature 
  def body
    @body && @body.length > 200 ? 'suppressed body output, see spec_helper' : @body
  end
end


# Fixtures, all here for now

# ESDB::Provider::Identity.fixture {{
#   :name => (name = /\w+/.gen),
#   :entities => 10.of {ESDB::Sc2::Match::Entity.make}
# }}
# 
# ESDB::Sc2::Identity.fixture {{
#   :name => (name = /\w+/.gen),
#   :entities => 10.of {ESDB::Sc2::Match::Entity.make}
# }}

ESDB::Identity.factory do
  name Randgen.name
  # entities {
  #   (1..10).collect{|n| ESDB::Sc2::Match::Entity.new}
  # }
end

ESDB::Sc2::Identity.factory do
  include_factory ESDB::Identity.factory
end

ESDB::Provider::Identity.factory do
  include_factory ESDB::Identity.factory
end

# 
# ESDB::Sc2::Match::Entity.fixture {{
#   :apm => rand(320),
#   :wpm => rand(200).to_f/100.0,
#   :replay => ESDB::Sc2::Match::Replay.make,
#   :win => rand(100) > 50,
#   :race => ['Z', 'P', 'T'][rand(3)]
# }}

ESDB::Sc2::Match::Entity.factory do
  apm     rand(320)
  wpm     rand(200).to_f/100.0
  # replay  ESDB::Sc2::Match::Replay.make
  win     rand(100) > 50
  race    ['Z', 'P', 'T'][rand(3)]
end

# 
# ESDB::Sc2::Match::Replay.fixture {{
#   :played_at => Time.now,
#   :processed_at => Time.now,
#   :md5 => Digest::MD5.hexdigest(Time.now.to_f.to_s)
# }}
# 

ESDB::Match.factory do
  played_at     Time.now
end

ESDB::Sc2::Match::Replay.factory do
  processed_at  Time.now
  md5           Digest::MD5.hexdigest(Time.now.to_f.to_s)
  match         ESDB::Match.make
end

