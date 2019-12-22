require 'yaml'
require 'find'
require 'forwardable'
require_relative 'helpers'
require_relative 'component'
require_relative 'components'
require_relative 'reference'
require_relative 'entity_manager'

module World
  class Fault < Helpers::Error; end
  class UnknownVirtual < Fault; end

  extend Helpers::Logging

  @entity_manager = EntityManager.new
  @systems = {}
  @views = []
  @entities_updated = []

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
        :add_component, :remove_component, :get_component, :get_components

    # reset the internal state of the World
    def reset!
      @entity_manager = EntityManager.new
      @systems.clear
      @views.clear
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
      @loading_dir = base
      Find.find(base) do |path|
        next if File.basename(path)[0] == '.'
        @entity_manager.load(path) if FileTest.file?(path)
      end
      @loading_dir = nil
      @entity_manager.resolve!
      entities.each { |e| update_views(e) }
    end

    # area_from_filename
    #
    # Given a filename, return the name of the area the Entities within that
    # file belong to.
    def area_from_filename(path)

      # If we're loading from a specific directory, then the area is the first
      # word after the loading_dir
      if @loading_dir && path =~ %r{#{@loading_dir}/([^/.]+)}
        $1
      else
        # otherwise it's just the filename without any extension
        File.basename(path).sub(/\..*$/, '')
      end
    end

    # find an entity by virtual id
    def by_virtual(virtual)
      @entity_manager.entity_by_virtual(virtual)
    end

    # find an entity by Entity id
    def by_id(id)
      @entity_manager.entity_by_id(id)
    end

    # register_system - register a system to run during update
    #
    # Arguments:
    #   ++name++  identifier for the system
    #   ++block++ block to run on entities with component types
    #
    # Parameters:
    #   ++:all++ entities must have all ++types++
    #   ++:any++ entities must have at least one of ++types++
    #   ++:none++ entities must not have any of ++types++
    #   method: system handler method (instead of block)
    def register_system(name, all: [], any: [], excl: [], method: nil, &block)

      # XXX need to try re-using EntityViews in the future
      view = @entity_manager.get_view(all: all, any: any, excl: excl)
      @views << view

      @systems[name] = [ view, block || method ]
      info "Registered #{name} system"
    end

    # update_views
    #
    # Used by the Entity class, notifies World of changes to an Entity for
    # propigation to the various views.
    #
    # Note: this is an asynchronous call; updates are processed at the start of
    # the World.update method.
    def update_views(entity)
      @entities_updated << entity
    end

    # update
    def update
      start = Time.now

      # apply the updates
      @entities_updated.uniq!
      @entities_updated.each { |e| @views.each { |v| v.update!(e) } }
      updates = @entities_updated.size
      @entities_updated.clear

      @systems.each do |system,(view, block)|
        view.each do |id,*comps|
          begin
            block.call(id, *comps)
          rescue Fault => ex
            error "Fault in system #{system}: #{ex}"
            @exceptions << ex
          rescue Exception => ex
            error "Exception in system #{system}: #{ex}"
            @exceptions << ex
          end
        end
      end
      delta = Time.now - start
      warn 'update exceeded time-slice; delta=%.04f > limit=%.04f' %
          [ delta, @update_frequency ] if delta > @update_frequency
      @update_time[@update_index] = {
        time: Time.now - start,
        entities_updated: updates
      }
      @update_index += 1
      @update_index = 0 if @update_index == @update_time.size
      true
    end
  end
end

require_relative 'world/constants'
require_relative 'world/helpers'
require_relative 'system'
require_relative 'command'
World.extend(World::Helpers)
