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

  # reset the world, load the test world, and populate it
  def reset_world
    Morrow.reset!
    Morrow.load_world
    Morrow.send(:prepare_systems)
    Morrow.instance_variable_set(:@update_start_time, Time.now)
  end

  # strip our color codes from a string
  def strip_color_codes(str)
    str.gsub(Morrow::TelnetServer::Connection::COLOR_CODE_REGEX, '')
  end

  # Toggle logging output.  Useful for tests that raise exceptions that go into
  # log_exception(), otherwise the rspec output would get very noisy.
  def toggle_logging
    logger = Morrow.config.logger

    @logger_orig_level ||= logger.level

    # If the logging level is set to debug, assume the test-runner wanted all
    # the logging output
    return if @logger_orig_level < Logger::INFO

    logger.level = @logger_orig_level == logger.level ?
        Logger::FATAL : @logger_orig_level
  end

  # run a command as an actor and capture the output
  def cmd_output(actor, cmd)
    player_output(actor).clear
    Morrow::Helpers.run_cmd(actor, cmd)
    strip_color_codes(player_output(actor))
  end

  # check if an entity has been, or is scheduled to be destroyed
  def entity_destroyed?(entity)
    !entity_exists?(entity) or
        Morrow.entities_to_be_destroyed.include?(entity)
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
