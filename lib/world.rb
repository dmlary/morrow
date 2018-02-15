require 'facets/hash/deep_rekey'
require_relative 'helpers'

module World
  @entities = []
  @entities_by_tag = Hash.new { |h,k| h[k] = [] }
  @entities_by_type = Hash.new { |h,k| h[k] = [] }
  @entities_by_id = {}

  @systems = []

  class << self
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
      @systems << [ System::CommandQueue.new,
                    proc { |e| e.has_component?(:command_queue) } ]
      @systems << [ System::Connections.new,
                    proc { |e| e.has_component?(:connection) } ]

      @base_dir = dir
      rooms = try_load('limbo/rooms.yml') or return
      rooms.each do |config|
        components = config[:components].map(&:first).map do |key, value|
          Component.new(key, value)
        end
        room = Entity.new(config[:type], *components)
        add_entity(room)
      end
    end
    attr_accessor :base_dir

    # get an enum for entities with a specific type
    def by_type(type)
      @entities_by_type[type.to_sym].to_enum
    end

    # get an entity by id
    def by_id(id)
      @entities_by_id[id]
    end

    # update
    def update
      @systems.each do |system, entity_matcher|
        system.update(@entities.select(&entity_matcher))
      end
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
