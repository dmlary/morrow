require 'yaml'
require 'find'
require 'forwardable'
require_relative 'helpers'
require_relative 'component'
require_relative 'components'
require_relative 'entity'
require_relative 'reference'
require_relative 'entity_manager'

module World
  class Fault < Helpers::Error; end
  class UnknownVirtual < Fault; end

  extend Helpers::Logging

  @entity_manager = EntityManager.new
  @systems = {}

  @exceptions = []

  @update_time = Array.new(3600, 0)
  @update_index = 0
  @update_frequency = 0.25 # seconds

  class << self
    extend Forwardable
    attr_reader :exceptions
    attr_accessor :entity_manager # setter exposed for testing
    def_delegators :@entity_manager, :entity_from_template, :entities

    # reset the internal state of the World
    def reset!
      @entity_manager = EntityManager.new
      @systems.clear
    end

    def new_entity(base: [], components: [])
      # XXX this components parameter may be problematic; what happens if we
      # want to merge?
      @entity_manager.new_entity(*base).add_component(*components)
    end

    # add_entity - add an entity to the world
    #
    # Arguments:
    #   arg: Entity or Reference
    #
    # Returns:
    #   Entity::Id
    def add_entity(entity)
      entity = entity.resolve if entity.is_a?(Reference)
      @entity_manager.add(entity)
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
    #   ++types++ List of Component types
    #   ++block++ block to run on entities with component types
    #
    # Parameters:
    #   ++:all++ entities must have all ++types++
    #   ++:any++ entities must have at least one of ++types++
    #   ++:none++ entities must not have any of ++types++
    #   method: system handler method (instead of block)
    def register_system(name, *types, method: nil, &block)
      p = types.last.is_a?(Hash) ? types.pop : {}
      @systems[name] = [ types, block || method ]
      info 'Registered system for %s' % [ types.inspect ]
    end

    # Need to create arrays to track entities with a subscribe set of
    # components.
    #
    # We notify the individual Component types of which arrays to manage as the
    # entity type is set/cleared; hooked into Entity#remove.
    #
    # register_system(:command_exec, :command_queue, &block)
    #   group = @entity_groups[[:command_queue]] ||= []
    #   @systems[:command_exec] = [ group, block ]
    #   Component.subscribe(:command_queue, group)
    #
    #
    # Component subscriptions: systems subscribe to component types
    #
    # XXX in #new_entity don't copy virtual?  End up with duplicate virtuals,
    # which should be unique.  Do we need to enforce unique?

    # update
    def update
      start = Time.now
      @systems.each do |system,(types, block)|
        entities.each do |entity|
          comps = types.inject([]) do |o, type|
            found = entity.get_components(type)
            break false if found.empty?
            o.push(*found)
          end or next

          begin
            block.call(entity, *comps)
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
      @update_time[@update_index] = Time.now - start
      @update_index += 1
      @update_index = 0 if @update_index == @update_time.size
      true
    end
  end
end

require_relative 'world/constants'
require_relative 'world/helpers'
World.extend(World::Helpers)
