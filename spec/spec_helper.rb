require 'yaml'
require 'facets/kernel/deep_clone'
require 'pry-rescue'
require 'pry-rescue/rspec'

$:.unshift(File.expand_path(__FILE__, '../lib'))
require 'world'
require 'telnet_server'

module Helpers
  def load_yaml_entities(buf)
    YAML.load(buf).map do |config|
      components = config['components'].map do |comp|
        key, value = comp.first
        Component.new(key, value)
      end
      Entity.new(config['type'], *components)
    end
  end

  def load_test_world
    World.reset!
    World.load(File.join(File.dirname(__FILE__), '../data/world/base.yml'))
    World.load(File.join(File.dirname(__FILE__), 'test-world.yml'))
  end

  # spawn_entities
  #
  # Kick off the spawning system one time
  def spawn_entities
    World.update
  end

  # generate a temporary filename
  def tmppath
    ts = Time.now.strftime('%Y%m%d')
    File.join(Dir.tmpdir,
        "rspec-morrow-#{$$}-#{ts}-#{rand(0xffffffff).to_s(16)}")
  end
end

RSpec.configure do |config|
  config.include(Helpers)

  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end

  config.before(:suite) do
    Helpers::Logging.logger.level = Logger::WARN
  end
end

# Helper for testing, add a method to strip our custom color codes
class String
  def strip_color_codes
    gsub(TelnetServer::Connection::COLOR_CODE_REGEX, '')
  end
end
