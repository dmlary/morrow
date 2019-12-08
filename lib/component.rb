require 'forwardable'
require 'facets/kernel/deep_clone'
require 'facets/hash/symbolize_keys'
require 'facets/hash/rekey'
require 'facets/hash/deep_rekey'
require 'facets/string/modulize'
require 'facets/kernel/constant'

class Component
  # setter function template for non-frozen fields; used in Component.field
  SETTER_METHOD = <<~METHOD
    define_method('%<name>s=') do |value|
      value = value.to_ref if value.is_a?(Entity)
      @%<name>s = (value.frozen? ? value : value.clone)
    end
  METHOD

  # setter function template for frozen fields; used in Component.field
  FREEZE_SETTER_METHOD = <<~METHOD
    define_method('%<name>s=') do |value|
      value = value.to_ref if value.is_a?(Entity)
      @%<name>s = (value.frozen? ? value : value.clone.freeze)
    end
  METHOD

  class << self
    def inherited(other)
      other.instance_variable_set(:@defaults, {})
      other.instance_variable_set(:@unique, true)
    end

    # find
    #
    # Given a human-readable component name as a String or Symbol, return the
    # Class for that Component type.
    def find(name)
      Kernel.constant("#{name}_component".modulize)
    end

    attr_accessor :defaults

    # Note that this Component will not be unique on the Entity
    def not_unique
      define_method(:unique?) { false }
      @unique = false
    end

    # Determine if this Component is unique in the Entity
    def unique?
      !!@unique
    end

    # To notify Entity#merge that this component should not be merged
    def not_merged
      define_method(:merge?) { false }
    end

    # Define a field in the Component
    #
    # Arguments:
    #   name: Name of the field
    #
    # Parameters:
    #   default: default value; defaults to nil
    #   freeze: if the setter should clone & freeze the value; default false
    #   clone: if the value should be cloned when set; default true
    def field(name, default: nil, freeze: false, clone: true)
      name = name.to_sym
      @defaults[name] = default

      if clone
        attr_reader name
        buf = (freeze ? FREEZE_SETTER_METHOD : SETTER_METHOD) % { name: name }
        instance_eval(buf, __FILE__, __LINE__)
      else
        attr_accessor name
      end
    end
  end

  # Component.new(1,2,3)    # Same number of fields
  # Component.new(a: 1, b: 2)
  def initialize(arg={})
    fields = self.class.defaults

    if arg.is_a?(Array)
      raise ArgumentError, "got #{arg}; need #{fields.size} values" unless
          arg.size == fields.size
      fields.each_with_index { |(k,_),i| fields[k] = arg[i] }
    elsif arg.is_a?(Hash)
      unknown = arg.keys - fields.keys
      raise ArgumentError,
          "Unknown component fields, #{unknown}, for #{self}" unless
              unknown.empty?
      fields.merge!(arg)
    else
      raise ArgumentError, "Unsupported argument type: #{arg.inspect}"
    end

    fields.each { |k,v| send("#{k}=", v) }
  end

  # unique?
  #
  # Return if this Component is unique per-Entity.
  #
  # Note, this method is replaced when the subclass calls #not_unique in it's
  # definition.
  def unique?
    true
  end

  # merge?
  #
  # Return if this Component should be merged by Entity#merge
  #
  # Note: this method is replaced when the subclass calls Component.not_merged
  def merge?
    true
  end
  attr_accessor :entity_id

  # to_h
  #
  # Return a Hash of field/value pairs
  #
  def to_h
    self.class.defaults.keys.inject({}) do |o,field|
      o[field] = send(field)
      o
    end
  end

  # diff
  #
  # Return a Hash of the difference between this Component and another
  # Component of the same type, or a Hash with the same field keys
  def diff(other)
    other = other.to_h if other.is_a?(self.class)
    raise ArgumentError, "Unsupported type for diff; #{other.inspect}" unless
        other.is_a?(Hash)
    to_h.reject { |k,v| other[k] == v }
  end

  # clone
  #
  # Clone a component
  def clone
    values = self.class.defaults.keys.map { |k| send(k) }
    self.class.new(values)
  end
end
