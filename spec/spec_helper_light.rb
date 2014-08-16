# A lighter spec_helper for specs that don't require anything but gems
# e.g. testing Citrus grammars (citrus_spec.rb)

ENV['RACK_ENV'] = 'test'
require 'rack/test'
