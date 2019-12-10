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
    @tasks = []
  end
  attr_reader :entities

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

  # entity_by_id
  #
  # lookup an entity by an entity id
  #
  # Arguments:
  #   id: Entity.id value
  #
  # Returns:
  #   Entity when found
  #   nil when not found
  def entity_by_id(id)
    obj = begin
      ObjectSpace._id2ref(id)
    rescue RangeError
      nil
    end
    @entities.include?(obj) ? obj : nil
  end

  # entity_by_virtual
  #
  # lookup an entity by a virtual id, or raise UnknownVirtual
  #
  # Arguments:
  #   virtual: id to be found in the VirtualComponent of an Entity
  #
  # Returns:
  #   Entity on success
  def entity_by_virtual(virtual)
    @entities.find { |e| e.get(VirtualComponent, :id) == virtual } or
        raise UnknownVirtual, virtual
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
