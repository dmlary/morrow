require 'set'
require_relative 'entity'
require_relative 'helpers'

class EntityManager
  include Helpers::Logging

  class UnsupportedFileType < ArgumentError; end
  class UnknownVirtual < ArgumentError; end

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
    @entities = []
    @deferred = []
  end
  attr_reader :entities, :pending

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
    @deferred.clear
  end

  # lookup an entity by a virtual id
  def entity_by_virtual(virtual)
    @entities.find { |e| e.get(:virtual) == virtual } or
        raise UnknownVirtual, virtual
  end

  # lookup an entity by an entity id
  def entity_by_id(id)
    ObjectSpace._id2ref(id)
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
  def new_entity(*others)
    out = others.flatten.inject(Entity.new) do |base,other|
      other = case other
        when Entity
          other
        when Reference
          other.resolve
        when String, Symbol
          entity_by_virtual(other)
        else
          raise ArgumentError, "unsupported other type: #{other.inspect}"
        end

      base.merge!(other)
    end
    out.rem_component(:virtual)
  end

  # define_entity
  #
  # Used by EntityManager::Loader::* to create and add an Entity to the
  # EntityManager.  This method supports deferred loading, so if a Reference
  # does not resolve at the time this is called, it will be added to the
  # deferred queue to be processed when #resolve! is called.
  #
  # If you're not a Loader, you probably want to use EntityManager#new_entity()
  #
  # Parameters:
  #   components: Array of Hashes; Hash is { component_type: component_fields }
  #   base: Array of virtuals to use as a base for this Entity
  #   area: Name of the area to-which this Entity belongs
  #   links: Array of References that should be updated to contain a Reference
  #          to the new Entity when #resolve! is called
  #   defer: set to false to disable deferring
  #
  # Returns:
  #   Entity on success
  #   nil on error
  def define_entity(components: [], base: [], area: nil, links: [],
      defer: true)
    entity = begin
      new_entity(base)
    rescue UnknownVirtual
      if defer
        @deferred << [ :define_entity, base: base,
            components: components, area: area, links: links ]
      end

      return nil
    end

    # Throw together an entity of just the components specified
    mods = Entity.new
    components.each do |type, config|
      component = Component.new(type, config)
      if area and component.type == :virtual and virtual = component.get
        component.set(virtual.gsub(/^([^:]+:)?/, '%s:' % area))
      end
      mods << component
    end

    # merge the modifications into our templated entity, and add it
    entity.merge!(mods)
    add(entity)

    # add any linking to the deferred list
    links.each do |ref|
      raise ArgumentError, "Not a Reference: #{ref}" unless
          ref.is_a?(Reference)
      @deferred << [ :link, ref: ref, entity: entity ]
    end

    # return the entity
    entity
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

  # resolve!
  #
  # Called after all #load() calls have been made; performs all deferred
  # entity creation & linking.
  #
  def resolve!
    info "resolving all entity references"
    loop do
      before = @deferred.size 

      @deferred.delete_if do |type, arg|
        case type
        when :define_entity
          define_entity(arg.merge(defer: false))
        when :link
          begin
            ref = arg[:ref]
            ref.resolve.set(*ref.component_field, arg[:entity])
            true
          rescue UnknownVirtual
            false
          end
        end
      end

      break if @deferred.empty? or @deferred.size == before
    end

    raise 'Failed to resolve all deferred items' unless @deferred.empty?
    info "all entity references resolved successfully"
  end
end

require_relative 'entity_manager/loader'
