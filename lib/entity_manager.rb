require 'set'
require_relative 'entity'
require_relative 'helpers'

class EntityManager
  include Helpers::Logging

  class Error < RuntimeError; end
  class UnsupportedFileType < Error; end
  class DuplicateId < Error; end
  class UnknownId < Error; end

  @loaders = Set.new
  class << self
    def register_loader(other)
      @loaders << other
    end

    def get_loader(path)
      @loaders.find { |l| l.support?(path) }
    end
  end

  def initialize()
    @tasks = []
    @views = {}

    # hash containing all the entities
    @entities = {}

    # used for assigning entity ids
    @entity_index = 0
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
    entity = @entities[id] = {}

    # merge any requested bases into the new entity
    base.each { |b| merge_entity(id, b) }

    # then add our components
    add_component(id, *components) unless components.empty?

    # return the id
    id
  end

  # merge_entity
  #
  # Merge one entity into another
  def merge_entity(dest_id, other_id)
    raise UnknownId, dest_id unless dest = @entities[dest_id]
    raise UnknownId, other_id unless others = @entities[other_id]

    others.each_pair do |klass, other|
      dest[klass] = other
    end
  end

  # add_component
  #
  # Add components to an entity
  def add_component(id, *components)
    raise UnknownId, id unless entity = @entities[id]

    components.each do |component|
      klass, instance = component.is_a?(Class) ?
          [ component, component.new ] :
          [ component.class, component ]

      if klass.unique?
        entity[klass] = instance
      else
        (entity[klass] ||= []) << instance
      end
    end
  end

  # get_component
  #
  # Get a component for an entity.
  def get_component(id, comp)
    raise UnknownId, id unless entity = @entities[id]
    entity[comp]
  end

  # Load entities from the file at +path+
  def load(path)
    loader = EntityManager.get_loader(path) or
        raise UnsupportedFileType, path
    info "loading entities from #{path}"
    loader.load(self, path)
  end

  # clear all entities from the system
  def clear
    @entities.clear
    @tasks.clear
    @views.clear
  end

  # get_view
  #
  # Get a view of specific entities
  def get_view(all: [], any: [], excl: [])
    excl << ViewExemptComponent unless
        (all + any + excl).include?(ViewExemptComponent)
    k = { all: all, any: any, excl: excl }
    @views[k] ||= View.new(k)
  end

  # new_entity
  #
  # Create a new Entity instance based off other Entity instances.  An +other+
  # may be an Entity instance, a Reference instance, or a String containing a
  # virtual.  A new Entity instance is created, then each +others+ in order is
  # merged to the Entity using `Entity#merge!`.
  #
  # Examples:
  #   bare_entity = new_entity    # equivalent to Entity.new
  #   player = new_entity('base:player', 'base:race/elf')
  #   chest = new_entity('base:obj/chest/locked')
  #
  def new_entity(*others, components: [], links: [], add: false)
    raise ArgumentError, 'cannot link without :add being set' unless
        add or links.empty?

    # Construct our output Entity by merging each of the others into an empty
    # Entity.
    out = others.flatten.inject(Entity.new) do |base,other|
      other = case other
        when Entity
          other
        when Reference
          other.entity
        when String, Symbol
          entity_by_virtual(other)
        else
          raise ArgumentError, "unsupported other type: #{other.inspect}"
        end

      base.merge!(other)
      base
    end

    # don't do any extra work if no components were provided
    unless components.empty?
      components.each do |add|
        if add.unique? and comp = out.get_component(add.class)
          comp.merge!(add)
        else
          out << add
        end
      end
    end

    # short circut the rest unless we're adding the enity
    return out unless add

    # Add the entity, and schedule any linking to it that needs to occur
    add(out)
    links.each { |r| schedule(:link, ref: r, entity: out) }

    out
  end

  # add
  #
  # Add an Entity to the EntityManager.  If the EntityManager is being serviced
  # by any System, this will make the Entity subject to that System.
  #
  # Arguments:
  #   entity: an Entity
  #
  def add(entity)
    raise ArgumentError, "not an Entity: #{entity.inspect}" unless
        entity.is_a?(Entity)
    @entities << entity
    entity
  end
  alias << add

  # schedule
  #
  # Add a task to be run during #resolve!
  #
  # Arguments:
  #   task: Task type; :link, or :new_entity
  #
  def schedule(task, args)
    @tasks.push([task, args])
    self
  end

  # resolve!
  #
  # Called after all #load() calls have been made; performs all deferred
  # entity creation & linking.
  #
  def resolve!
    info "running pending tasks"

    loop do
      before = @tasks.size 

      @tasks.delete_if do |type, arg|
        begin
          case type

          # New entity we pass off to the #new_entity method; it'll raise an
          # UnknownVirtual error if any of the bases don't exist.
          when :new_entity
            arg.is_a?(Array) ? new_entity(*arg) : new_entity(arg)

          # For linking, we'll resolve the value of the Reference; if it's an
          # Array we'll push our Entity Reference into it, otherwise we'll just
          # replace the value.
          #
          # Reference#value will raise UnknownVirtual if the Reference won't
          # resolve.
          when :link
            value = arg[:ref].value
            if value.is_a?(Array)
              value << arg[:entity].to_ref
            else
              arg[:ref].value = arg[:entity]
            end
          end

          # If we got this far, the task has been completed; we can delete it
          true

        # If we get an UnknownVirtual exception, that means we're missing some
        # dependency for this task, so we should try it again on the next pass.
        rescue UnknownVirtual
          false   # do not delete from @tasks
        end
      end

      # Break out of the loop if all the tasks have been completed, or none of
      # them could be completed this time.
      break if @tasks.empty? or @tasks.size == before
    end

    raise 'Failed to resolve all deferred items' unless @tasks.empty?
    info "all pending tasks completed successfully"
  end
end

require_relative 'entity_manager/loader'
require_relative 'entity_manager/view'
