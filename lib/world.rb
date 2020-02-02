require 'yaml'
require 'find'
require 'forwardable'
require 'benchmark'
require_relative 'helpers'
require_relative 'component'
require_relative 'entity_manager'

module World
  class Fault < ::Helpers::Error; end
  class UnknownVirtual < Fault; end

  module Importer; end

  extend ::Helpers::Logging

  @entity_manager = EntityManager.new
  @systems = []

  @exceptions = []

  @update_time = Array.new(3600, 0)
  @update_index = 0
  @update_frequency = 0.25 # seconds

  class << self
    extend Forwardable
    attr_reader :exceptions
    attr_reader :entity_manager
    alias em entity_manager   # shortcut for my sanity

    def_delegators :@entity_manager, :entities,
        :add_component, :remove_component, :get_component, :get_components,
        :get_view

    # create_entity
    #
    # Create an entity
    def create_entity(id: nil, base: [], components: [])
      base = [ base ] unless base.is_a?(Array)
      entity = em.create_entity(id: id, base: base, components: components)
      get_component!(entity, :metadata).base = base
      entity
    end

    # destroy_entity
    #
    # Destroy an entity, and update whatever SpawnComponent it may have come
    # from.
    def destroy_entity(entity)
      debug("destroying entity #{entity}")

      # update any spawn point that this entity is going away
      begin
        if meta = get_component(entity, :metadata) and
            meta.spawned_by and
            spawn = get_component(meta.spawned_by, :spawn)
          spawn.active -= 1
          spawn.next_spawn ||= Time.now + spawn.frequency
        end
      rescue EntityManager::UnknownId
        # spawn entity has already been destroyed; continue
      end

      # remove the entity from whatever location it was in
      begin
        if location = entity_location(entity) and
            cont = get_component(location, :container)
          cont.contents.delete(entity)
        end
      rescue EntityManager::UnknownId
        # container entity has already been destroyed; continue
      end

      em.destroy_entity(entity)
    end

    # get_component!
    #
    # Get a unique component for the entity.  If one does not yet exist, it
    # will create the component.
    def get_component!(entity, type)
      em.get_component(entity, type) or em.add_component(entity, type)
    end

    # reset the internal state of the World
    def reset!
      @entity_manager = EntityManager.new
      @systems.clear
    end

    # load the world
    #
    # Arguments:
    #   ++dir++ directory containing world
    #
    # Returns: self
    def load(base)
      info "loading world from #{base} ..."
      @loader = Loader.new(@entity_manager)
      Find.find(base) do |path|
        next if File.basename(path)[0] == '.' or !FileTest.file?(path)

        # Grab the area name from the path
        area = if path =~ %r{#{base}/([^/.]+)}
          $1
        else
          # support loading a single filename as the world
          File.basename(path).sub(/\..*$/, '')
        end

        @loader.load(path: path, area: area)
      end
      @loader.finish
      info "completed loading world from #{base}"
    end

    # register_systems
    #
    # Register the systems to be run
    def register_systems
      @systems << System::Connections
      @systems << System::CommandQueue
      @systems << System::Spawner
      @systems << System::Teleport
    end

    # update
    def update
      bm = Benchmark.measure do
        @systems.each do |handler|
          handler.view.each do |id, *comps|
            begin
              handler.update(id, *comps)
            rescue Fault => ex
              error "Fault in system #{handler}: #{ex}"
              @exceptions << ex
            rescue Exception => ex
              error "Exception in system #{handler}: #{ex}"
              @exceptions << ex
            end
          end
        end
        em.flush_updates
      end

      warn "update exceeded timeslice #{bm}" if bm.real > 0.25

      @update_time[@update_index] = bm
      @update_index += 1
      @update_index = 0 if @update_index == @update_time.size
      true
    end

    # log_exception
    #
    # Log an exception to the log, and store it for inspection if we're running
    # in development.
    def log_exception(ex)
      ::Helpers::Logging.log_exception(ex)
      exceptions << ex
    end
  end
end

require_relative 'world/script_safe_helpers'
require_relative 'world/helpers'
require_relative 'world/loader'
require_relative 'system'
require_relative 'script'
require_relative 'components'
require_relative 'world/constants'
require_relative 'command'
World.extend(World::Helpers)
