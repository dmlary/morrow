require 'yaml'
require 'facets/hash/deep_rekey'
require_relative 'helpers'
require_relative 'component'
require_relative 'entity'
require_relative 'reference'

module World
  class Fault < ::RuntimeError
    def initialize(msg, *extra)
      super(msg)
      @extra = extra
    end
    attr_accessor(:extra)
  end

  extend Helpers::Logging

  @entities = []
  @entities_by_tag = Hash.new { |h,k| h[k] = [] }
  @entities_by_type = Hash.new { |h,k| h[k] = [] }
  @entities_by_id = {}

  @systems = []

  @update_time = Array.new(3600, 0)
  @update_index = 0
  @update_frequency = 0.25 # seconds

  class << self
    attr_reader :entities

    # reset the internal state of the World
    def reset!
      @entities.clear
      @entities_by_tag.clear
      @entities_by_type.clear
      @entities_by_id.clear
      @systems.clear
    end

    # new_entity - allocate a new entity, add it to the world, return it's ID
    #
    # Arguments:
    #   ++type++ Entity type
    #
    # Parameters:
    #   ++:tag++ Tag for this entity
    #
    # Returns:
    #   Entity::Id
    def new_entity(*args)
      entity = Entity.new(*args)
      add_entity(entity)
    end

    # add_entity - add an entity to the world
    #
    # Arguments:
    #   ++entity++ entity
    #
    # Returns:
    #   Entity::Id
    def add_entity(entity)
      @entities << entity
      @entities_by_type[entity.type] << entity if entity.type
      @entities_by_tag[entity.tag] << entity if entity.tag
      @entities_by_id[entity.id] = entity
      entity.id
    end

    # load the world
    #
    # Arguments:
    #   ++dir++ directory containing world
    #
    # Returns: self
    def load(dir)
      @base_dir = dir
      rooms = try_load('limbo/rooms.yml') or return
      rooms.each do |config|
        components = config[:components].map do |comp_config|
          case comp_config
          when Hash
            Component.new(*comp_config.flatten)
          when String, Symbol
            Component.new(comp_config)
          else
            raise TypeError,
                "unsupported component config type: #{comp_config.inspect}"
          end
        end
        entity = add_entity(Entity.new(config[:type], *components))
      end

      resolve_references

      # All the rooms have been loaded, let's connect them
      @rooms_by_vnum = {}

      exits = []
      @entities_by_type[:room].each do |room|
        @rooms_by_vnum[room.get(:vnum)] = room
        exits.push(*room.get_component(:exit, true))
      end
      exits.each do |ex|
        ex.set(:room_id, @rooms_by_vnum[ex.get(:to_vnum)].id)
      end
    end
    attr_accessor :base_dir

    # get an enum for entities with a specific type
    def by_type(type)
      @entities_by_type[type.to_sym].to_enum
    end

    # Look up entities by id
    #
    # Arguments:
    #   ++arg++ entity id, entity or an Array of the two
    #   ++block++ optional block to call with id & entity if arg is Array
    #
    # Notes:
    #   If called with a block, { |id, entity| ... }, entity will be nil when
    #   the id provided does not reference a valid Entity.  The caller must
    #   handle this case, and call World::Helpers.missing_entity() with the
    #   appropriate context for the entity id.
    #
    # Usage:
    #   World.by_id(nil)          # => nil
    #   World.by_id(2131)         # => entity
    #   World.by_id(entity)       # => entity
    #
    #   World.by_id(2131) { |id,e| ... }     # ArgumentError
    #   World.by_id(entity) { |id,e| ... }   # ArgumentError
    #
    #   World.by_id([nil])        # => [ ]
    #   World.by_id([2131])       # => [ entity ]
    #   World.by_id([entity])     # => [ entity ]
    #   World.by_id(2131) { |id,e| ... }     # yield(id, e)
    #   World.by_id(entity) { |id,e| ... }   # yield(id, e)
    def by_id(arg, &block)
      raise ArgumentError, 'block not supported without Array argument' if
          block and !arg.is_a?(Array)

      case arg
      when nil
        nil
      when Integer
        if entity = @entities_by_id[arg]
          block ? block.call(entity.id, entity) : entity
        end
      when Entity
        if entity = @entities_by_id[arg.id]
          block ? block.call(entity.id, entity) : entity
        end
      when Array
        if block
          arg.delete_if do |id|
            next true if id.nil?
            if entity = by_id(id)
              block.call(entity.id, entity)
              false
            else
              # caller will report the entity as missing because they have more
              # context
              block.call(id, nil)
              true
            end
          end
        else
          out = []
          arg.delete_if do |id|
            next true if id.nil?
            entity = by_id(id) or (missing_entity(id: id); next true)
            out << entity if entity
            false
          end
          out
        end
      else
        raise ArgumentError, "unsupported arg: #{arg.inspect}"
      end
    end

    # register_system - register a system to run during update
    #
    # Arguments:
    #   ++types++ List of Component types
    #   ++block++ block to run on entities with component types
    #
    # Parameters:
    #   ++:all++ entities must have all ++types++
    #   ++:any++ entities must have at least one of ++types++
    #   ++:none++ entities must not have any of ++types++
    def register_system(*types, &block)
      p = types.last.is_a?(Hash) ? types.pop : {}
      @systems << [ types, block ]
      info 'Registered system for %s' % [ types.inspect ]
    end

    # update
    def update
      start = Time.now
      @systems.each do |types, block|
        @entities.each do |entity|
          comps = types.inject([]) do |o, type|
            found = entity.get_component(type, true)
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

    private

    def try_load(*path)
      filename = File.expand_path(File.join(*path), @base_dir)
      return nil unless File.exists?(filename) 
      data = YAML.load_file(filename)

      if data.is_a?(Array)
        data.map { |v| v.is_a?(Hash) ? v.deep_rekey { |k| k.to_sym } : v }
      elsif data.is_a?(Hash)
        data.deep_rekey { |k| k.to_sym }
      else
        data
      end
    end

    # traverse all Components, and resolve all Reference instances
    def resolve_references
      @entities.each do |entity|
        entity.components.each do |component|
          component.each_pair do |key, ref|
            next unless ref.is_a?(Reference)

            # Resolution steps
            # * determine the Entity type this reference is for
            # * Using Entity type's resolution to look up an entity of this
            #   type

            # Grab the type & destination component from the class.  Allow the
            # type to be overridden by the reference itself ([<type>/]value)
            types, comp = component.class.ref(key)
            m = ref.value.match(%r{^(?:(?<type>.*)/)?(?<value>.*?)$})
            types = [m[:type]] if m[:type]

            entity = find_entity(m[:value], type: types)

            binding.pry
          end
        end
      end
    end
  end
end

require_relative 'world/helpers'
World.extend(World::Helpers)
