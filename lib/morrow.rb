require 'eventmachine'
require 'rack'
require 'yaml'
require 'find'
require 'benchmark'
require 'facets/string/indent'

module Morrow; end
require_relative 'morrow/version'
require_relative 'morrow/logging'

# Morrow MUD server
#
# Example usage:
#
#   # start the server, telnet on port 5000, http on port 8080
#   Morrow.run
#
#   # start the server, telnet on port 6000, no web server
#   Morrow.run(telnet_port: 6000)
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

  # All exceptions from Morrow will be subclassed from this
  class Error < StandardError; end

  # An entity id, unknown to the EntityManager was used
  class UnknownEntity < Error; end

  # The requested resource is set to nil on the entity
  class MissingResource < Error; end

  # The entity provided is an invalid target for method.  This is raised when
  # an entity is missing a component or field needed to perform some action.
  class InvalidEntity < Error; end

  # This error is raised when the actor entity and the target entity are not in
  # the same room.
  class EntityNotPresent < Error; end

  # These errors are raised by move_entity() to note that the entity wouldn't
  # fit in the destination
  class EntityWillNotFit < Error; end
  class EntityTooLarge < EntityWillNotFit; end
  class EntityTooHeavy < EntityWillNotFit; end

  @exceptions = []
  @systems = []
  @cycle = 0
  @entities_to_be_destroyed = []

  class << self

    # List of exceptions that have occurred in ths system.  When run in
    # development environment, Pry.rescued() can be used to debug these
    # exceptions.
    attr_reader :exceptions

    # EntityManager instance containing all entities for the world.
    attr_reader :em

    # Time at which the latest Morrow.update ran.  This is used by
    # Morrow::Helpers.now to provide a unified time across all systems/helpers
    # to make it easier to schedule things without worrying about millisecond
    # delays caused by other systems.
    attr_reader :update_start_time

    # This is the list of entities that need to be destroyed in this update.
    # Don't access this directly, use Morrow::Helpers.destroy_entity
    attr_reader :entities_to_be_destroyed

    # Get the server configuration.
    def config
      @config ||= Configuration.new
    end

    # Load the world.
    #
    # **NOTE** This is automatically called from Morrow#run; it's just exposed
    # publicly as a convenience for debugging & testing.
    def load_world
      raise Error, 'World has already been loaded!' if @em && !@em.empty?
      reset! unless @em

      load_path(File.expand_path('../../data/morrow-base', __FILE__)) if
          config.load_morrow_base
      load_path(config.world_dir)
      info 'world has been loaded'
    end

    # This will wipe the world entirely clean.  Used for testing
    def reset!
      @em = EntityManager.new(components: config.components)
      @systems.clear
      @cycle = 0
      @entities_to_be_destroyed.clear
    end

    # Run the server.  More advanced configuration can be done using the block
    # syntax.
    #
    # Parameters:
    # * +host+ host to bind to; default: '0.0.0.0', 'localhost' in development
    # * +telnet_port+ port to listen for telnet connections; default: 5000
    # * +http_port+ port to listen for http connections; default: 8080
    #
    def run(host: nil, telnet_port: 5000, http_port: 8080)

      # configure the server
      config.host = host if host
      config.telnet_port = telnet_port
      config.http_port = http_port

      yield config if block_given?

      info 'Loading the world'
      load_world
      prepare_systems

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
          # Set up a periodic timer to update the world every quarter second.
          EventMachine::PeriodicTimer.new(@config.update_interval) do
            Morrow.update
          end

          Rack::Handler.get('thin').run(WebServer.app,
              Host: config.host, Port: config.http_port, signals: false) if
                  config.http_port

          TelnetServer.start(config.host, config.telnet_port)
        rescue Exception => ex
          log_exception(ex)
        end
      end
    end

    # Run all the registered systems
    def update
      @update_start_time = Time.now

      # Flush the updates right before we run the systems.  This makes writing
      # tests easier, otherwise we have to run update twice after modifying a
      # test entity.
      # XXX need to benchmark this also
      @em.flush_updates

      @systems.each do |system, interval, view|
        bm = Benchmark.measure do

          # don't update the system unless it's supposed to run this cycle.  We
          # still store benchmark data for skipped systems to keep the math
          # simple in the `show sys` command.
          next if interval != 1 && (@cycle % interval != 0)

          view.each do |args|
            system.update(*args)
          rescue
            entity, *components = args;
            error('system update exception: %s' % system)
            error('    entity: %s' % entity)
            error('    components:')
            components.pretty_inspect.indent(8).lines
                .each { |l| error(l.chomp) }
            log_exception($!)
          end
        end
        system.append_system_perf(bm)
      end

      # Destroy the requested entities and clear the list
      @entities_to_be_destroyed
          .each { |e| @em.destroy_entity(e) }
          .clear

      @cycle += 1
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

    # Load entities from a specific path.
    def load_path(base)
      loader = Loader.new
      Find.find(base)
          .select { |path| File.basename(path) =~ /^[^.].*\.yml$/ }
          .sort
          .each do |path|
        info "loading #{path} ..."
        loader.load_file(path)
      end
      loader.finalize
    end

    # Pepare the array of systems for periodic execution in .update
    def prepare_systems
      @systems = @config.systems.map do |system|
        view_args = system.view

        # Add { excl: :template } to the args unless the system already put
        # :template somewhere in the args.
        unless view_args.values.flatten.include?(:template)
          view_args[:excl] ||= []
          view_args[:excl] << :template
        end

        view = @em.get_view(**view_args)

        # determine on which cycle this system should be run
        interval = (system.frequency / @config.update_interval).to_i

        [ system, interval, view ]
      end
    end
  end
end

require_relative 'morrow/component'
require_relative 'morrow/helpers'
require_relative 'morrow/components'
require_relative 'morrow/system'
require_relative 'morrow/telnet_server'
require_relative 'morrow/configuration'
require_relative 'morrow/command'
require_relative 'morrow/web_server'
require_relative 'morrow/entity_manager'
require_relative 'morrow/loader'
require_relative 'morrow/script'

# dynamically load all the commands
Dir.glob(File.expand_path('../morrow/command/**.rb', __FILE__)).each do |file|
  require file
end
