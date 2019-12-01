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
              component.unique? and has_component?(component.type)
      @components << component
      component.entity_id = id
    end
    self
  end
  alias << add_component

  def rem_component(*components)
    components = components.flatten
    @components.reject! { |c| components.include?(c) }
    self
  end

  alias id __id__

  # Get a Reference to this entity
  def ref
    @ref ||= Reference.new(self)
  end

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
    @components.select { |c| c.type == type }
  end

  # set a given field of a component to the supplied value
  #
  # Arguments:
  #   ++type++ Component type (Symbol/String)
  #   ++field++ component field name (default: :value)
  #   ++value++ value to set field to
  #
  # Returns:
  #   self
  def set(*args)
    raise ArgumentError, "insufficient arguments" if args.size < 2
    raise ArgumentError, "too many arguments" if args.size > 3

    type = args.shift.to_sym

    comp = get_component(type) or raise ComponentNotFound,
        "type=#{type} entity=#{self.inspect}"
    comp.set(*args)
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
    comp.get(field)
  end

  def has_component?(type)
    !!@components.find { |c| c.type == type }
  end

  def encode_with(coder)
    coder.tag = nil
    coder['type'] = @type.to_s
    coder['components'] = @components
  end

  # Entity
  def merge!(*others)
    others.flatten.compact.each do |other|
      raise ArgumentError, 'other must be an Entity' unless
          other.is_a?(Entity)

      other.components.each do |theirs|
        if theirs.unique? && mine = get_component(theirs.type)
          theirs.modified_fields.each do |field, value|
            mine.set(field, value)
          end
        else
          add_component(theirs.clone)
        end
      end
    end
    self
  end
end
