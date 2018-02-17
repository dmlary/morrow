require 'exception_binding'

$:.unshift(File.expand_path(__FILE__, '../lib'))
require 'telnet_server'

RSpec.configure do |config|
  unless ENV['PRY'].nil? or ENV['PRY'].to_i == 0
    config.before(:suite) { ExceptionBinding.enable }

    config.after(:each) do |example|
      next unless example.exception
      next unless stack = example.exception.stack
      stack.pry(stack.frames.reverse.find { |f| f.file =~ /_spec\.rb$/ })
    end
  end
end

# Helper for testing, add a method to strip our custom color codes
class String
  def strip_color_codes
    gsub(TelnetServer::Connection::COLOR_CODE_REGEX, '')
  end
end
