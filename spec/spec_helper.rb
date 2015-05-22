$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
# require 'feature_toggle_service'

require 'bundler/setup'
Bundler.setup

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

require 'pry'
require 'feature_toggle_service'

require 'webmock/rspec'
require 'naught'

WebMock.disable_net_connect!(:allow => "codeclimate.com")

RSpec.configure do |config|
  # some (optional) config here
end
