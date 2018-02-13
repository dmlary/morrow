require 'yaml'
require 'pp'
require 'eventmachine'
require_relative 'lib/component'
require_relative 'lib/telnet_server'
require_relative 'lib/world'
require_relative 'lib/exception_binding'

ExceptionBinding.enable

begin
  Component.import(YAML.load_file('./data/components.yml'))
  binding.pry

  EventMachine::run do
    EventMachine.error_handler do |e|
      TelnetServer.exceptions.push(e)
      e.stack.pry if e.stack
    end

    begin
      World.load('./data')
      Thread.new { TelnetServer.pry; exit }
      TelnetServer.start('0.0.0.0', 1234)
    rescue Exception => ex
      ex.stack.pry
      raise ex
    end
  end
end
