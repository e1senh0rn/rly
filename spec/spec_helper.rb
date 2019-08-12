require "rubygems"
require "bundler"
Bundler.setup :default, :development, :test
require 'pry'

require "./spec/support/fixture_helpers"

if ENV["COVERAGE"] == 'true'
  require "simplecov"
  SimpleCov.minimum_coverage 100
  SimpleCov.start do
    add_filter '/spec/'
  end
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.add_setting :file_fixture_path, default: 'spec/fixtures/files'
  config.include FixtureHelpers
end
