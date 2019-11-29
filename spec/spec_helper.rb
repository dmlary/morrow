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
end

RSpec.configure do |config|
  config.include(Helpers)
end

# Helper for testing, add a method to strip our custom color codes
class String
  def strip_color_codes
    gsub(TelnetServer::Connection::COLOR_CODE_REGEX, '')
  end
end
