require 'yaml'
require 'facets/kernel/deep_clone'

$:.unshift(File.expand_path(__FILE__, '../lib'))
require 'exception_binding'
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

  unless ENV['PRY'].nil? or ENV['PRY'].to_i == 0
    config.before(:suite) do
      ExceptionBinding.enable
      ExceptionBinding.pry_when do |ex|
        next if ex.stack
            .has_frame_in_class?(RSpec::Matchers::BuiltIn::RaiseError)
        ex.stack.frames.find { |f| f.file =~ /_spec\.rb$/ }
      end
    end
  end
end

# Helper for testing, add a method to strip our custom color codes
class String
  def strip_color_codes
    gsub(TelnetServer::Connection::COLOR_CODE_REGEX, '')
  end
end
