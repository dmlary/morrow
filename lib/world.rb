require 'yaml'
require 'find'
require 'forwardable'
require 'benchmark'
require_relative 'helpers'
require_relative 'component'
require_relative 'components'
require_relative 'entity_manager'

module World
  class Fault < Helpers::Error; end
  class UnknownVirtual < Fault; end

  extend Helpers::Logging

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
    def_delegators :@entity_manager, :entities, :create_entity, :destroy_entity,
        :add_component, :remove_component, :get_component, :get_components,
        :get_view

    # reset the internal state of the World
    def reset!
      @entity_manager = EntityManager.new
      @systems.clear
    end

    # get_component!
    #
    # Get a unique component for the entity.  If one does not yet exist, it
    # will create the component.
    def get_component!(entity, type)
      em.get_component(entity, type) or em.add_component(entity, type)
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
      @loading_dir = nil
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
  end
end

require_relative 'world/constants'
require_relative 'world/helpers'
require_relative 'world/loader'
require_relative 'system'
require_relative 'command'
World.extend(World::Helpers)
