#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'eventmachine'
require 'pry'
require 'pry-remote'
require_relative '../lib/world'
require_relative '../lib/telnet_server'
require_relative '../lib/web_server'

Pry.enable_rescuing!

# Load the entire world, and register all the systems
begin
  ARGV << File.join(File.dirname(__FILE__), '../data/world') if ARGV.empty?
  ARGV.each { |path| World.load(path) }
  World.register_systems
rescue Exception => ex
  Pry.rescued(ex)
  raise ex
end

Thread.abort_on_exception = true

# Kick off a debugging thread
Thread.new do
  loop do
    begin
      World.pry_remote('localhost', 4321)
    rescue DRb::DRbConnError
      # noop
    end
  end
end

# In development automatically reload the web server when the source file is
# modified.  This saves us a lot of headaches.
Thread.new do
  path = File.absolute_path(File.join(
      File.dirname(__FILE__), '../lib/web_server.rb'))
  mtime = File.mtime(path)

  loop do
    if (t = File.mtime(path)) > mtime
      World.debug('web server modified; attempting to reloading it ...')
      mtime = t
      begin

        # Try loading the file; if it is successful, reset (clear) the web
        # server, and load it again.  We do it this way to avoid having a
        # non-operational web-interface due to a syntax error in the file.
        load(path)
        WebServer.reset!  # this will clear all the routes
        load(path)
        World.info('web server reloaded')
      rescue Exception => ex
        World.error 'failed to reload web server'
        World.log_exception(ex)
      end
    end
    sleep 3
  end
end

# run the telnet server, blocking this main thread
EventMachine::run do
  EventMachine.error_handler do |ex|
    World.log_exception(ex)
    # Pry.rescued(ex)
  end

  begin
    EventMachine::PeriodicTimer.new(World::PULSE) { World.update }

    Rack::Handler.get('thin')
        .run(WebServer, signals: false)
    TelnetServer.start('0.0.0.0', 1234)
  rescue Exception => ex
    World.log_exception(ex)
    Pry.rescued(ex)
    raise ex
  end
end
