require 'yaml'
require 'facets/hash/deep_rekey'
require_relative 'helpers'
require_relative 'component'
require_relative 'entity'

module World
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
        components = config[:components].map(&:first).map do |key, value|
          Component.new(key, value)
        end
        room = Entity.new(config[:type], *components)
        add_entity(room)
      end

      # All the rooms have been loaded, let's connect them
      @rooms_by_vnum = {}
      exits = []
      @entities_by_type[:room].each do |room|
        @rooms_by_vnum[room.get_value(:vnum)] = room
        exits.push(*room.get(:exit, true))
      end
      exits.each do |ex|
        ex.room_id = @rooms_by_vnum[ex.to_vnum].id
      end
    end
    attr_accessor :base_dir

    # get an enum for entities with a specific type
    def by_type(type)
      @entities_by_type[type.to_sym].to_enum
    end

    # get an entity by id
    def by_id(id)
      return nil if id.nil?
      return id if id.is_a?(Entity)
      @entities_by_id[id]
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
            found = entity.get(type, true)
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
  end
end
