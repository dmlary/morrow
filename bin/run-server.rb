#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'eventmachine'
require 'pry'
require_relative '../lib/world'
require_relative '../lib/telnet_server'

Pry.enable_rescuing!

begin
  EventMachine::run do
    EventMachine.error_handler do |ex|
      TelnetServer.exceptions.push(ex)
      Helpers::Logging.log_exception(ex)
      World.exceptions.push(ex)
      # Pry.rescued(ex)
    end

    begin
      # Load all the things we need
      ARGV << File.join(File.dirname(__FILE__), '../data/world') if ARGV.empty?
      ARGV.each { |path| World.load(path) }
      World.register_systems

      EventMachine::PeriodicTimer.new(World::PULSE) { World.update }

      # Kick off a debugging thread
      Thread.new { World.pry }

      # Start the server
      TelnetServer.start('0.0.0.0', 1234)
    rescue Exception => ex
      Pry.rescued(ex)
      raise ex
    end
  end
end
