require_relative 'helpers'

class Entity
  class Error < Helpers::Error; end
  class DuplicateUniqueComponent < Error; end
  class ComponentNotFound < Error; end

  def initialize(*components, tags: [])
    @components = []
    components.flatten.each { |c| add_component(c) }
  end

  # components
  #
  # Return an array of all the components in this entity.
  def components
    @components.clone.freeze
  end

  # add_component
  #
  # Add a component to this Entity.
  #
  # Arguments:
  #   *components: components to be added
  #
  def add_component(*components)
    components.flatten.each do |component|
      raise DuplicateUniqueComponent.new("component already present in entity",
          self, component) if
              component.unique? and has_component?(component.class)
      @components << component
      component.entity_id = id
    end
    self
  end
  alias << add_component

  # remove_component
  #
  # Remove Component instances from this Entity by Componant instance or
  # Component Class.
  def rem_component(*args)
    args.flatten!
    @components.reject! do |comp|
      args.include?(comp) or args.include?(comp.class)
    end
    self
  end

  # id
  #
  # Returns the id for this Entity
  alias id __id__

  # to_ref
  #
  # Get a Reference to this Entity
  #
  # Returns:
  #   Reference
  def to_ref
    @ref ||= Reference.new(self)
  end

  # get_component
  #
  # Get a Component from this Entity.  If the Component is non-unique, this
  # method will raise an error (use #get_components) instead.
  #
  # Arguments:
  #   type: Class, or something resolvable by Component.find
  #
  # Returns:
  #   nil: Component not present in class
  #   Component instance on success
  def get_component(type)
    type = Component.find(type) unless type.is_a?(Class)
    raise ArgumentError,
        "You must use Entity#get_components() for non-unique Components" unless
            type.unique?
    get_components(type).first
  end

  # get_components
  #
  # Return an Array of all of a specific type of Component in this Entity
  #
  # Arguments:
  #   type: Class, or something resolvable by Component.find
  #
  # Returns:
  #   Array
  def get_components(type)
    type = Component.find(type) unless type.is_a?(Class)
    @components.select { |c| c.class == type }
  end

  # set a given field of a component to the supplied value
  #
  # Examples:
  #   e = Entity.new(HealthComponent.new(current: 10, max: 20))
  #   e.set(HealthComponent, current: 12)
  #
  #   e = Entity.new(VirtualComponent.new(id: "base:obj/ball"))
  #   e.set(VirtualComponent, id: "limbo:obj/red-ball")
  #
  # Arguments:
  #   ++type++ Component type (Symbol/String)
  #   ++field++ component field name (default: :value)
  #   ++value++ value to set field to
  #
  # Returns:
  #   self
  def set(type, pairs)
    comp = get_component(type) or raise ComponentNotFound,
        "type=#{type} entity=#{self.inspect}"

    pairs.each do |key, value|
      begin
        key = '%s=' % key.to_s
        comp.send(key, value)
      rescue NoMethodError
        raise ArgumentError, "field #{key} not found in #{comp}"
      end
    end

    self
  end

  # get
  #
  # Get Component field values for unique Components.  Non-unique Components
  # will raise an exception from Entity#get_component(), and should use
  # Entity#get_components instead.
  #
  # Examples:
  #   id = Entity.get(:virtual, :id)
  #   id = Entity.get(VirtualComponent, :id)
  #   area, hints = Entity.get(LoadedComponent, :area, :hints)
  #
  # Arguments:
  #   type: Class, or something resolvable by Component.find
  #   fields: Array of field values to get
  #
  def get(type, *fields)
    raise ArgumentError, 'no fields specified' unless fields.size > 0
    comp = get_component(type)

    results = fields.map do |field|
      begin
        comp ? comp.send(field) : nil
      rescue NoMethodError
        raise ArgumentError, "field #{field} not found in #{comp}"
      end
    end
  
    results.size == 1 ? results.first : results
  end

  # has_component?
  #
  # Returns true if the Entity has a Component of the specified type.
  #
  def has_component?(type)
    get_components(type).size > 0
  end

  # merge!
  #
  # Merge the components & component values of another Entity into this entity.
  # See spec/lib/entity_spec.rb for more details
  #
  def merge!(*others, all: false)
    others.flatten.compact.each do |other|
      raise ArgumentError, 'other must be an Entity' unless
          other.is_a?(Entity)

      other.components.each do |theirs|
        next unless all || theirs.merge?
        if theirs.unique? && mine = get_component(theirs.class)
          theirs.diff(mine).each { |k,v| mine.send("#{k}=", v) }
        else
          add_component(theirs.clone)
        end
      end
    end
    self
  end
end
