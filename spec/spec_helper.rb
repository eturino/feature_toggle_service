$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
# require 'feature_toggle_service'

require 'bundler/setup'
Bundler.setup

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'pry'
require 'feature_toggle_service'

RSpec.configure do |config|
  # some (optional) config here
end
