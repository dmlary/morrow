require_relative 'helpers'

class Entity
  class Error < Helpers::Error; end
  class DuplicateUniqueComponent < Error; end
  class ComponentNotFound < Error; end
  Id = Integer

  def initialize(*components, tags: [])
    @components = []
    components.flatten.each { |c| add_component(c) }
  end

  def components
    @components.clone.freeze
  end

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

  def rem_component(*args)
    args.flatten!
    @components.reject! do |comp|
      args.include?(comp) or args.include?(comp.class)
    end
    self
  end

  alias id __id__

  # Get a Reference to this entity
  def to_ref
    @ref ||= Reference.new(self)
  end
  alias ref to_ref

  def inspect
    buf = "#<%s:0x%010x components=[" %
        [ self.class, id, ]
    @components.each do |component|
      buf << "\n    #{component.inspect}"
    end
    buf << "]>"
  end

  def get_component(type)
    found = get_components(type)

    raise MultipleInstancesFound,
        "multiple instances of component #{type} found in #{entity}; " +
        "consider using Entity#get_components() instead" if found.size > 1

    found.first
  end

  def get_components(type)
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

  # get a given field of a component; return nil if no component match
  #
  # Arguments:
  #   ++type++ Component type (Symbol/String)
  #   ++field++ component field name (default: :value)
  #
  def get(type, field=:value)
    comp = get_component(type) or return nil
    begin
      comp.send(field.to_sym)
    rescue NoMethodError
      raise ArgumentError, "field #{field} not found in #{comp}"
    end
  end

  def has_component?(type)
    !!@components.find { |c| c.class == type }
  end

  # Entity
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
