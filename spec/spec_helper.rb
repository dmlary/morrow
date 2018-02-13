require 'exception_binding'

$:.unshift(File.expand_path(__FILE__, '../lib'))

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
