require 'eventmachine'
require 'rack'
require 'yaml'

module Morrow; end
require_relative 'morrow/version'
require_relative 'morrow/configuration'
require_relative 'morrow/logging'
require_relative 'morrow/telnet_server'

# Morrow MUD server
#
# Example usage:
#
#   # start the server, telnet on port 1234, http on port 8080
#   Morrow.run
#
#   # start the server, telnet on port 6000, no web server
#   Morrow.run(port: 6000)
#
#   # Complex invocation
#   Morrow.run do |c|
#     c.env = :production   # override APP_ENV environment variable
#     c.host = '0.0.0.0'
#     c.port = 1234
#     c.web_port = 8080
#   end
#
module Morrow
  extend Logging

  class Error < StandardError; end

  @exceptions = []

  class << self

    # List of exceptions that have occurred in ths system.  When run in
    # development environment, Pry.rescued() can be used to debug these
    # exceptions.
    attr_reader :exceptions

    # Get the server configuration.
    def config
      @config ||= Configuration.new
    end

    # Run the server.  More advanced configuration can be done using the block
    # syntax.
    #
    # Parameters:
    # * +host+ host to bind to; default: '0.0.0.0', 'localhost' in development
    # * +telnet_port+ port to listen for telnet connections; default: 1234
    # * +http_port+ port to listen for http connections; default: 8080
    #
    def run(host: nil, telnet_port: nil, http_port: nil)

      # configure the server
      config.host = host if host
      config.telnet_port = telnet_port if telnet_port
      config.http_port = http_port if http_port

      yield config if block_given?

      info 'Morrow starting in %s mode' % config.env
      WebServer::Backend.set :environment, config.env

      # If we're running in development mode,
      #   * pull in and start running Pry on stdin
      #   * enable pry-rescue
      #   * allow reloading of the web server code
      #   * start a thread dedicated to running Pry
      if config.development?
        require 'pry'
        require 'pry-rescue'

        Pry.enable_rescuing!
        start_reloader
      end

      # Run everything in the EventMachine loop.
      EventMachine::run do
        EventMachine.error_handler { |ex| log_exception(ex) }

        begin
          # Set up a periodic timer to update the world
          # EventMachine::PeriodicTimer.new(World::PULSE) { World.update }

          Rack::Handler.get('thin').run(WebServer.app,
              Host: config.host, Port: config.http_port, signals: false) if
                  config.http_port

          TelnetServer.start(config.host, config.telnet_port)
        rescue Exception => ex
          log_exception(ex)
          Pry.rescued(ex)
        end
      end
    end

    private

    # Start a thread dedicated to reloading resources as they change on disk.
    # For the moment, this only does the web server.
    def start_reloader
      Thread.new do
        base = File.dirname(__FILE__)
        path = File.join(base, 'morrow/web_server/backend.rb')
        mtime = File.mtime(path)

        loop do
          if (t = File.mtime(path)) > mtime
            debug('web server modified; attempting to reload ...')
            mtime = t

            begin
              # We do this in stages; try to load the file, and if it's
              # successful, reset the web server, then load it again.  The
              # reset is necessary, otherwise the routes from the previous web
              # server definition take precidence.
              load(path)
              WebServer::Backend.reset!
              load(path)
              info('web server reloaded')
            rescue Exception => ex
              error('failed to reload web server')
              log_exception(ex)
            end
          end

          sleep 5
        end
      end
    end
  end
end

require_relative 'morrow/web_server'
require_relative 'morrow/component'
require_relative 'morrow/entity_manager'
