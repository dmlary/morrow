require 'ostruct'

class Entity
  class NotDefined < ArgumentError; end
  class AlreadyDefined < ArgumentError; end
  class ComponentNotFound < ArgumentError; end
  class FieldNotFound < ArgumentError; end
  Id = Integer

  @types ||= {}

  class << self
    def reset!
      @types.clear
    end

    # define a type
    #
    # Arguments:
    #   Array - an array of component types
    #
    # Parameters:
    #   ++:components++ Array of component types, or hash of component/default
    #   ++:includes++ Array of entity types to include
    #
    def define(type, *args)
      type = type.to_sym
      raise AlreadyDefined, type if @types.has_key?(type)

      p = args.last.is_a?(Hash) ? args.pop : {}
      out = OpenStruct.new(components: [], includes: [])

      # handle the includes first, they are easy
      out.includes.push(*[p[:include]].flatten.compact.map(&:to_sym))

      # components = [
      #   [ type, default ]
      # ]

      # for all the arguments, we're just adding components without default
      # values, so add them to the components list as arrays of a single
      # element (the type as a symbol).
      out.components.push(*args.map { |a| [ a.to_sym ] })

      # process the components parameter by type
      if p[:components].is_a?(Hash)
        # key/value pairs are type & defaults.  Add them as pairs to the
        # components
        p[:components].each_pair do |type, defaults|
          out.components.push([type.to_sym, defaults])
        end
      elsif p[:components].is_a?(Array)
        # if we got an array, the contents may be an array of types, or a hash
        # of type/defaults
        p[:components].each do |component|
          case component
          when String, Symbol
            out.components.push([component.to_sym])
          when Hash
            name, default = component.first
            component = [ name.to_sym ]
            if default.is_a?(Array)
              component.push(*default)
            else
              component.push(default)
            end
            out.components.push(component)
          else
            raise ArgumentError, "unsupported type #{component.inspect}"
          end
        end
      elsif p.has_key?(:components)
        # same if we only got a single argument
        out.components.push([p[:components].to_sym])
      end
      @types[type] = out
      out
    end

    def get(type)
      @types[type.to_sym]
    end

    def import(data)
      [data].flatten.each do |entity|
        entity = entity.symbolize_keys
        define(entity.delete(:type), entity)
      end
    end

    def types
      @types.keys
    end
  end

  def components
    @components.clone.freeze
  end

  def initialize(*components)
    @components = components.flatten
    @components.each { |c| c.entity_id = id }
  end

  def add(*components)
    @components.push(*components)
    components.each { |c| c.entity_id = id }
    self
  end
  alias << add
  alias id __id__

  def inspect
    buf = "#<%s:0x%010x components=[" %
        [ self.class, id, ]
    @components.each do |component|
      buf << "\n    #{component.inspect}"
    end
    buf << "]>"
  end

  def remove(*components)
    @components.reject! { |c| components.include?(c) }
    self
  end

  def get_component(type, multiple=false)
    return @components.select { |c| type.include?(c.type) } if
        type.is_a?(Array)

    type = type.to_sym

    multiple == false ?
      @components.find { |c| c.type == type } :
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

    type = args.shift

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

  # Get a Reference to this entity
  def ref
    @ref ||= Reference.new(self)
  end
end
