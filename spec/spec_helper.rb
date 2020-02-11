require "bundler/setup"
require "morrow"
require 'pry-rescue'
require 'pry-rescue/rspec'

module Helpers
  # generate a temporary filename
  def tmppath
    ts = Time.now.strftime('%Y%m%d')
    File.join(Dir.tmpdir,
        "rspec-morrow-#{$$}-#{ts}-#{rand(0xffffffff).to_s(16)}")
  end

  # get the player output
  def player_output(entity)
    get_component!(entity, :connection).buf
  end
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Morrow.config.logger.level = Logger::ERROR
  Morrow.config.world_dir =
      File.expand_path('../../data/morrow-test', __FILE__)

  config.include Morrow::Helpers
  config.include Helpers
end
