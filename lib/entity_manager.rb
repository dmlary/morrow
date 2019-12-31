require 'securerandom'
require 'facets/string/snakecase'
require_relative 'helpers'

class EntityManager
  include Helpers::Logging

  class Error < RuntimeError; end
  class UnsupportedFileType < Error; end
  class DuplicateId < Error; end
  class UnknownId < Error; end
  class ComponentPresent < Error; end

  def initialize()
    @entities = {}          # hash containing all the entities
    @comp_map = {}          # mapping Component -> [ index, klass ]
    @comp_index_max = -1    # maximum index in the Entity Array
    @views = {}             # any active views
    @pending_updates = []   # pending updates to views
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
    id ||= SecureRandom.uuid

    # make sure the id isn't a duplicate
    raise DuplicateId, id if @entities.has_key?(id)

    begin
      entity = @entities[id] = []

      # merge any requested bases into the new entity
      base.each { |b| merge_entity(id, b) }

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

  # merge_entity
  #
  # Merge one entity into another.  If both entities have a common unique
  # Component, the Component will be merged into dest.
  def merge_entity(dest_id, other_id)
    raise UnknownId, dest_id unless dest = @entities[dest_id.to_s]
    raise UnknownId, other_id unless others = @entities[other_id.to_s]

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
  def destroy_entity(*entity)
    entity.flatten.each { |e| @entities.delete(e) }
  end

  # add_component
  #
  # Add components to an entity
  def add_component(id, *components)
    raise UnknownId, id unless entity = @entities[id]

    out = components.map do |arg|
      key, instance = case arg
      when Component
        [ arg.class, arg ]
      when Symbol
        [ arg, nil ]
      when Class
        [ arg, arg.new ]
      else
        raise ArgumentError, "unsupported argument type: #{arg.inspect}"
      end

      # find the index for this component class in the entity array
      index, klass = (@comp_map[key] || add_component_type(key))
      instance ||= klass.new

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
    raise UnknownId, id unless entity = @entities[id]

    index, klass = @comp_map[type]

    if klass.nil?
      klass = type.is_a?(Symbol) ? Component.find(type) : type
    end

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
    raise UnknownId, id unless entity = @entities[id]

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
        index, klass = add_component_type(type)
        raise ArgumentError, "#{klass} present more than once in args" if
            seen.include?(klass)
        seen << klass
        [ index, klass ]
      end
      o
    end

    args[:excl] << add_component_type(ViewExemptComponent) unless
        seen.include?(ViewExemptComponent)

    if view = @views[args]
      return view
    end

    # New view, let's update it for every known entity in the system
    view = View.new(args)
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

  # add_component_type
  #
  # Add a component type to EntityManager.  This is called from #add_component
  # when the Component class doesn't already have an index in the Entity Array.
  #
  # Arguments:
  #   type: Component class, or Symbol (Component name)
  #
  # Returns:
  #   index: index of component in entity array
  #   class: Component class
  def add_component_type(type)
    if entry = @comp_map[type]
      return entry
    end

    type = Component.find(type) if type.is_a?(Symbol)

    raise ArgumentError, "invalid component type: #{type.inspect}" unless
        type.is_a?(Class) && type.superclass == Component

    index = (@comp_index_max += 1)
    entry = [ index, type ]
    @comp_map[type] = entry

    begin
      Module.const_get(type.to_s)
      sym = type.to_s.snakecase.sub(/_component$/, '').to_sym
      @comp_map[sym] = entry
    rescue NameError
      # the class hasn't been assigned a constant, so don't create a symbol
      # shortcut for the component.
    end

    entry
  end

  # update_views
  #
  # Called internally during add_component/remove_component to update all the
  # views of the change to the entity
  def update_views(id, components)
    @pending_updates << [id, components]
  end
end

require_relative 'entity_manager/view'
