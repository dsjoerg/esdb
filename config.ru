require './esdb'

use ESDB::RequestLogger

# ESDB.logger defaults to INFO, goes to DEBUG when ENV['DEBUG'] is present
use Rack::Cors, logger: ESDB.logger do
  allow do
    origins '*'
    resource '/*', :headers => :any, :methods => [:get, :post, :options]
  end
end

# Will return JSONP if the callback param (callback) is present in a request
use Rack::JSONP

map '/' do
  run ESDB::App.new
end

map '/api' do
  run ESDB::API.new
end

# Resque plugins that provide tabs for the web app
require 'resque/status_server'
require 'resque-job-stats/server'

map '/resque' do
  run Resque::Server.new
end