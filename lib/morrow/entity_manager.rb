require 'securerandom'

class Morrow::EntityManager

  class UnsupportedFileType < Morrow::Error; end
  class DuplicateId < Morrow::Error; end
  class UnknownId < Morrow::Error; end
  class ComponentPresent < Morrow::Error; end
  class UnknownComponent < Morrow::Error; end

  # Initialize a new EntityManager.
  #
  # Parameters:
  # * components: Hash of component name => class
  #
  def initialize(components: Morrow.config.components)
    @entities = {}          # hash containing all the entities
    @views = {}             # any active views
    @pending_updates = []   # pending updates to views

    index = 0
    @comp_map = components.inject({}) do |map,(name,klass)|
      raise ArgumentError,
          "duplicate component #{klass} in #{components.inspect}" if
              map.has_key?(klass)
      map[name] = map[klass] = [ index, klass ]
      index += 1
      map
    end
  end
  attr_reader :entities

  # create_entity
  #
  # Create a new entity.
  #
  # Parameters:
  # * id: entity id; default random UUID
  # * base: entity ids to layer together as the base for this entity
  # * components: components to add to this entity; see #add_component
  #
  # Returns:
  #   String: Entity ID
  #
  # Examples:
  #   em.create_entity
  #       # => '4b647a23-54bc-48ba-86ae-4f050439bd08'
  #   em.create_entity(id: 'test:id')     # => 'test:id'
  #
  #   em.create_entity(base: 'test:id')
  #       # => '17854d7b-27b3-475b-ae8a-d785432008e5'
  #   em.create_entity(id: 'base:passage/locked',
  #       base: 'base:passage',
  #       components: [ ClosableComponent.new(locked: true) ])
  #                                       # => 'base:passage/locked'
  def create_entity(id: nil, base: [], components: [])
    base = [ base ] unless base.is_a?(Array)
    components = [ components ] unless components.is_a?(Array)

    # create an id if one wasn't provided
    id ||= SecureRandom.uuid

    # make sure the id isn't a duplicate
    raise DuplicateId, "entity already exists: #{id.inspect}" if
        @entities.has_key?(id)

    begin
      entity = @entities[id] = []

      # merge any requested bases into the new entity
      base.each do |b|
        merge_entity(id, b)
      rescue UnknownId
        raise UnknownId, "unknown base entity: #{b}"
      end

      # clear the modified flags on all of our components; they came from the
      # base entities.
      entity.flatten.each { |c| c.clear_modified! if c }

      # then add our components
      add_component(id, *components) unless components.empty?
    rescue Exception
      @entities.delete(id)
      raise
    end

    # return the id
    id
  end

  # check to see if there are any entities defined
  def empty?
    @entities.empty?
  end

  # Check to see if a given entity exists
  def entity_exists?(id)
    @entities.has_key?(id)
  end

  # Ensure a given entity id exists, or raise an UnknownId error
  def entity_exists!(id)
    @entities.has_key?(id) or raise UnknownId, "unknown entity: #{id}"
  end

  # merge_entity
  #
  # Merge one entity into another.  If both entities have a common unique
  # Component, the Component will be merged into dest.
  def merge_entity(dest_id, other_id)
    dest_id = dest_id.to_s unless dest_id.is_a?(String)
    raise UnknownId, "unknown dest entity: #{dest_id}" unless
        dest = @entities[dest_id]
    raise UnknownId, "unknown other entity: #{other_id}" unless
        others = @entities[other_id.to_s]

    others.each_with_index do |other,i|
      if other.is_a?(Array)
        mine = (dest[i] ||= [])
        other.each { |o| mine << o.clone }
      elsif other && mine = dest[i]
        mine.merge!(other)
      elsif other != nil
        dest[i] = other.clone
      end
    end

    update_views(dest_id, dest)

    dest
  end

  # destroy_entity
  #
  # Destroy an entity.
  #
  # XXX likely this is gonna cause all sorts of madness.  Imagine running
  # through all the systems (A & B).  A destroys entity X, but views aren't
  # updated until after systems run, so B tries to do something with X, still
  # in their view.  The view components are still there, but if they try to
  # access something else in the entity, it won't be present.
  def destroy_entity(*entities)
    entities.flatten.each do |entity|
      @entities.delete(entity)
      update_views(entity, [])
    end
  end

  # add_component
  #
  # Add components to an entity.  If the component is unique, and it already
  # exists in the entity, the new component will be merged with the existing.
  # See Component#merge! for details on Component merging.
  #
  # Examples:
  #
  #   # Add the closable component to chest, and make it closed
  #   add_component('chest', closable: { closed: true })
  #
  #   # Set an existing component instance to an entity
  #   instance = some_method_that_returns_a_component_instance
  #   add_component('player', instance)
  #
  def add_component(id, *components)
    raise UnknownId, "unknown entity #{id}" unless entity = @entities[id]

    out = components.map do |component|
      type, args, instance = case component
        when Symbol
          component
        when Morrow::Component
          [ component.class, nil, component ]
        when Hash
          raise ArgumentError, "multiple keys in #{component.inspect}" if
              component.size != 1
          component.first
        else
          raise ArgumentError,
              "unsupported argument type: #{component.inspect}"
        end

      index, klass = @comp_map[type]
      raise UnknownComponent,
          "unknown component: #{component.inspect}" unless index

      instance ||= klass.new(args || {})

      if klass.unique?
        if value = entity[index]
          value.merge!(instance)
        else
          entity[index] = instance
        end
      else
        (entity[index] ||= []) << instance
      end

      instance
    end

    # update all of the views for the changes
    update_views(id, entity)

    out.size == 1 ? out.first : out
  end

  # get_component
  #
  # Get a component for an entity.
  def get_component(id, type)
    raise UnknownId, "unknown entity #{id}" unless entity = @entities[id]

    index, klass = @comp_map[type]

    klass ||= type.is_a?(Symbol) ? Morrow.config.components[type] : type

    raise ArgumentError,
        'use #get_components for non-unique Components' if klass &&
            !klass.unique?

    return nil unless index

    entity[index]
  end

  # get_components
  #
  # Get all instances of a Component for the Entity.
  def get_components(id, comp)
    raise UnknownId, "unknown entity #{id}" unless entity = @entities[id]

    index, _ = @comp_map[comp]
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
  #   type: Component instance, or Component name (Symbol)
  #
  # Returns:
  #   Array of component instances removed
  def remove_component(id, type)
    raise UnknownId, "unknown entity #{id}" unless entity = @entities[id]

    # Massage our type to handle someone passing in a component instance
    type, instance = type.is_a?(Morrow::Component) ?
        [ type.class, type ] :
        [ type, nil ]

    index, _ = @comp_map[type]

    # if it's an unknown component, or there's nothing for that component in
    # the entity, return an empty array
    return [] unless index and components = entity[index]

    out = if instance.nil? || components.__id__ == instance.__id__
      entity[index] = nil
      components
    elsif components.is_a?(Array)
      components.delete(instance)
    else
      []
    end

    # package the removed instances as an array
    out = [ out ] unless out.is_a?(Array)

    # update all of the views if there were changes
    update_views(id, entity) unless out.empty?

    out
  end

  # get_view
  #
  # Get an EntityManager::View instance for a given criteria
  def get_view(all: [], any: [], excl: [])
    seen = []
    args = { all: all, any: any, excl: excl }.inject({}) do |o,(key,val)|
      val = [ val ].flatten.compact
      o[key] = val.map do |type|
        index, klass = @comp_map[type]
        raise UnknownComponent, "unknown component: #{type}" unless index

        raise ArgumentError, "#{klass} present more than once in args" if
            seen.include?(klass)
        seen << klass
        [ index, klass ]
      end
      o
    end

    if view = @views[args]
      return view
    end

    # New view, let's update it for every known entity in the system
    view = View.new(**args)
    entities.each { |entity,comps| view.update!(entity, comps) }
    @views[args] = view
  end

  # flush_updates
  #
  # After systems have run, this is called to notify the views of changes to
  # the entities.  This is necessary because we cannot update a view's list of
  # entities while iterating through it.
  def flush_updates
    @pending_updates.each do |update|
      @views.each_value { |v| v.update!(*update) }
    end
    @pending_updates.clear
  end

  private

  # update_views
  #
  # Called internally during add_component/remove_component to update all the
  # views of the change to the entity
  def update_views(id, components)
    @pending_updates << [id, components]
  end
end

require_relative 'entity_manager/view'
