#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'eventmachine'
require_relative 'lib/exception_binding'
require_relative 'lib/helpers'
require_relative 'lib/component'
require_relative 'lib/entity'
require_relative 'lib/world'
require_relative 'lib/system'
require_relative 'lib/telnet_server'

ExceptionBinding.enable

begin
  EventMachine::run do
    EventMachine.error_handler do |e|
      TelnetServer.exceptions.push(e)
      e.stack.pry if e.stack
    end

    begin
      # Load all the things we need
      Component.import(YAML.load_file('./data/components.yml'))
      Entity.import(YAML.load_file('./data/entities.yml'))
      World.load('./data/world')

      # Kick off the update thread
      # Unit          Pulses           Seconds
      # 1 pulse       1 pulse          1/4 second
      # 1 round       12 pulses        3 seconds
      # 1 heartbeat   12 pulses        3 seconds
      # 1 turn        30 pulses        7.5 seconds
      # 1 tick        300 pulses       75 seconds / 1.25 real minutes
      # 1 mud hour    300 pulses       75 seconds / 1.25 real minutes
      # 1 mud day     7200 pulses      1800 seconds / 30 real minutes
      # 1 mud month   252000 pulses    63000 seconds / 17.5 real hours
      # 1 mud year    4284000 pulses   1071000 seconds / 12.3 real days

      EventMachine::PeriodicTimer.new(0.25) { World.update }

      # Kick off a debugging thread
      Thread.new { TelnetServer.pry }

      # Start the server
      TelnetServer.start('0.0.0.0', 1234)
    rescue Exception => ex
      ex.stack.pry
      raise ex
    end
  end
end
