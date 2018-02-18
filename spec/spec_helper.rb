require 'exception_binding'

$:.unshift(File.expand_path(__FILE__, '../lib'))
require 'telnet_server'

RSpec.configure do |config|
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
