require 'yaml'
require 'find'
require 'forwardable'
require_relative 'helpers'
require_relative 'component'
require_relative 'entity'
require_relative 'reference'
require_relative 'entity_manager'

module World
  class Fault < Helpers::Error; end
  class UnknownVirtual < Fault; end

  extend Helpers::Logging

  @entity_manager = {}
  @systems = {}

  @exceptions = []

  @update_time = Array.new(3600, 0)
  @update_index = 0
  @update_frequency = 0.25 # seconds

  class << self
    extend Forwardable
    attr_reader :exceptions, :entity_manager
    def_delegators :@entity_manager, :entity_from_template, :entities

    # reset the internal state of the World
    def reset!
      @entity_manager.clear
      @systems.clear
    end

    def new_entity(*others)
      @entity_manager.new_entity(*others)
    end

    # add_entity - add an entity to the world
    #
    # Arguments:
    #   ++entity++ entity
    #
    # Returns:
    #   Entity::Id
    def add_entity(entity)
      @entity_manager.add(entity)
    end

    # load the world
    #
    # Arguments:
    #   ++dir++ directory containing world
    #
    # Returns: self
    def load(base)
      @entity_manager = EntityManager.new
      Find.find(base) do |path|
        next if File.basename(path)[0] == '.'
        @entity_manager.load(path) if FileTest.file?(path)
      end
      @entity_manager.resolve!
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
    def register_system(name, *types, &block)
      p = types.last.is_a?(Hash) ? types.pop : {}
      @systems[name] = [ types, block ]
      info 'Registered system for %s' % [ types.inspect ]
    end

    # update
    def update
      start = Time.now
      @systems.values.each do |types, block|
        entities.each do |entity|
          comps = types.inject([]) do |o, type|
            found = entity.get_components(type)
            break false if found.empty?
            o.push(*found)
          end or next

          begin
            block.call(entity, *comps)
          rescue Exception => ex
            ex.stack.pry if ex.stack
            raise ex
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
