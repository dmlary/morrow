require 'set'
require 'facets/string/snakecase'
require_relative 'entity'
require_relative 'helpers'

class EntityManager
  include Helpers::Logging

  class Error < RuntimeError; end
  class UnsupportedFileType < Error; end
  class DuplicateId < Error; end
  class UnknownId < Error; end

  def initialize()
    @entities = {}          # hash containing all the entities
    @entity_index = 0       # used for assigning entity ids
    @comp_map = {}          # mapping Component -> [ index, unique ]
    @comp_index_max = -1    # maximum index in the Entity Array
    @views = {}             # any active views
  end
  attr_reader :entities

  # create_entity
  #
  # Create a new entity.
  #
  # Returns:
  #   String: Entity ID
  #
  # Examples
  #   em.create_entity                    # => 'none:empty-8391893'
  #   em.create_entity(id: 'test:id')     # => 'test:id'
  #   em.create_entity(base: 'test:id')   # => 'test:id-32193'
  #   em.create_entity(id: 'base:passage/locked',
  #       base: 'base:passage',
  #       components: [ ClosableComponent.new(locked: true) ])
  #                                       # => 'base:passage/locked'
  def create_entity(id: nil, base: [], components: [])
    base = [ base ] unless base.is_a?(Array)
    components = [ components ] unless components.is_a?(Array)

    # create an id if one wasn't provided
    if id.nil?
      id = '%s-%d' % [ base.empty? ? 'none:empty' : base.first, @entity_index ]
      @entity_index += 1
    end

    # make sure the id isn't a duplicate
    raise DuplicateId, id if @entities.has_key?(id)
    entity = @entities[id] = []

    # merge any requested bases into the new entity
    base.each { |b| merge_entity(id, b) }

    # then add our components
    add_component(id, *components) unless components.empty?

    # return the id
    id
  end

  # merge_entity
  #
  # Merge one entity into another.  If both entities have a common unique
  # Component, the Component will be merged into dest.
  def merge_entity(dest_id, other_id)
    raise UnknownId, dest_id unless dest = @entities[dest_id]
    raise UnknownId, other_id unless others = @entities[other_id]

    others.each_with_index do |other,i|
      if other.is_a?(Array)
        mine = (dest[i] ||= [])
        other.each { |o| mine << o.clone }
      elsif mine = dest[i]
        mine.merge!(other)
      else
        dest[i] = other
      end
    end
  end

  # add_component_type
  #
  # Add a component type to EntityManager.  This is called from #add_component
  # when the Component class doesn't already have an index in the Entity Array.
  def add_component_type(klass)
    raise ArgumentError, "invalid component type: #{klass.inspect}" unless
        klass.is_a?(Class) && klass.superclass == Component

    # look if there's already an index for it
    index, _ = @comp_map[klass]
    return index if index

    index = (@comp_index_max += 1)
    entry = [ index, klass.unique? ]
    @comp_map[klass] = entry

    begin
      Module.const_get(klass.to_s)
      sym = klass.to_s.snakecase.sub(/_component$/, '').to_sym
      @comp_map[sym] = entry
    rescue NameError
      # the class hasn't been assigned a constant, so don't create a symbol
      # shortcut for the component.
    end

    index
  end

  # add_component
  #
  # Add components to an entity
  def add_component(id, *components)
    raise UnknownId, id unless entity = @entities[id]

    components.map do |component|

      # from the argument, get both a klass and an instance
      klass, instance = component.is_a?(Class) ?
          [ component, component.new ] :
          [ component.class, component ]

      # find the index for this component class in the entity array
      index, _ = (@comp_map[klass] || add_component_type(klass))

      if klass.unique?
        entity[index] = instance
      else
        (entity[index] ||= []) << instance
      end

      instance
    end
  end

  # get_component
  #
  # Get a component for an entity.
  def get_component(id, comp)
    raise UnknownId, id unless entity = @entities[id]

    index, unique = @comp_map[comp]
    return nil unless index

    raise ArgumentError,
        'use #get_components for non-unique Components' unless unique
    entity[index]
  end

  # get_components
  #
  # Get all instances of a Component for the Entity.
  def get_components(id, comp)
    raise UnknownId, id unless entity = @entities[id]

    index, unique = @comp_map[comp]
    return [] unless index

    out = entity[index] || []
    out.is_a?(Array) ? out.clone.freeze : [ out ]
  end

  # remove_component
  #
  # Remove a Component instance, or class of Component from an Entity.
  #
  # Arguments:
  #   id: Entity id
  #   type: Component, Component instance, or Component name (Symbol)
  #
  # Returns:
  #   Array of component instances removed
  def remove_component(id, type)
    raise UnknownId, id unless entity = @entities[id]

    # Massage our type to handle someone passing in a component instance
    type, instance = type.is_a?(Component) ?
        [ type.class, type ] :
        [ type, nil ]

    index, _ = @comp_map[type]

    # if it's an unknown component, or there's nothing for that component in
    # the entity, return an empty array
    return [] unless index and components = entity[index]

    out = if instance.nil? || components == instance
      entity[index] = nil
      components
    elsif components.is_a?(Array)
      components.delete(instance)
    else
      []
    end

    out.is_a?(Array) ? out : [ out ]
  end

  # get_view
  #
  # Get an EntityManager::View instance for a given criteria
  def get_view(all: [], any: [], excl: [])
    excl << ViewExemptComponent unless
        (all + any + excl).include?(ViewExemptComponent)
    k = { all: all, any: any, excl: excl }
    @views[k] ||= View.new(k)
  end

  private

  # update_views
  #
  # Called internally during add_component/remove_component to update all the
  # views of the change to the entity
  def update_views(id, change)
  end
end

require_relative 'entity_manager/loader'
require_relative 'entity_manager/view'
