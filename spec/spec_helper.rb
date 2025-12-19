ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'

  add_group 'Models', 'model'
  add_group 'Services', 'services'
  add_group 'Commands', 'commands'
  add_group 'Workers', 'workers'
  add_group 'Config', 'config'
end

require_relative '../app'
require 'rack/test'
require 'webmock/rspec'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = false

  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  # Clean database before each test
  config.before(:each) do
    Task.where(Sequel.lit('1=1')).delete
  end

  # Disable logging during tests
  config.before(:suite) do
    LOGGER.level = Logger::FATAL
  end
end

WebMock.disable_net_connect!(allow_localhost: true)

def app
  TyphoonApp
end
