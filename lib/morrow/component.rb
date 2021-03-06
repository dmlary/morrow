require 'forwardable'
require 'facets/string/modulize'
require 'facets/kernel/constant'

class Morrow::Component
  class InvalidValue < Morrow::Error; end

  class << self
    def inherited(other)
      other.instance_variable_set(:@fields, {})
      other.instance_variable_set(:@unique, true)
    end

    # Set/get the description of this component.  Will only set the first time.
    def desc(desc=nil)
      @desc ||= desc
    end

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

    # This component should not be saved
    def no_save
      define_method(:save?) { false }
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
    #   valid: Array or Proc to check validity of values
    #   type: Value type
    #   desc: description of the value
    #
    def field(name, default: nil, freeze: false, clone: true, valid: nil,
        type: String, desc: nil)
      name = name.to_sym
      variable = "@#{name}".to_sym
      modified = "@__modified_#{name}".to_sym

      raise ArgumentError, 'the field "hash" is reserved' if name == :hash

      # Permitting them to be lazy here; the default value will automatically
      # be added to a valid Array.
      valid << default if valid.is_a?(Array) and !valid.include?(default)

      # note the details about the field in the class
      @fields[name] = { desc: desc, type: type, default: default,
          valid: valid }

      # declare the getter
      attr_reader name

      # the setter is a little more complicated
      define_method('%s=' % name) do |value, set_modified: true|

        case valid
        when Array, Range
          raise InvalidValue,
              "invalid value #{value} for #{self.class}.#{name}" unless
                  valid.include?(value)
        when Proc
          raise InvalidValue,
              "invalid value #{value} for #{self.class}.#{name}" unless
                  valid.call(value)
        end

        # We don't need to do anything to a frozen variable, but if it's not
        # frozen, if we're supposed to clone it, do so, and if we're supposed
        # to freeze it, also do that.
        unless value.frozen?
          value = value.clone if clone
          value.freeze if freeze
        end

        # set the instance variable for this field
        instance_variable_set(variable, value)

        # also, unless explicitly told not to, mark this variable as modified.
        # This exception is used by the initializer to set the defaults.
        instance_variable_set(modified, true) if set_modified
      end
    end

    attr_accessor :fields
  end

  # Component.new(1,2,3)    # Same number of fields
  # Component.new(a: 1, b: 2)
  def initialize(arg={})
    fields = self.class.fields

    case arg
    when Array
      raise ArgumentError, "got #{arg}; need #{fields.size} values" unless
          arg.size == fields.size
      fields.each_with_index { |(k,_),i| send("#{k}=", arg[i]) }

    when Hash
      unknown = arg.keys - fields.keys
      raise ArgumentError,
          "Unknown component fields, #{unknown}, for #{self}" unless
              unknown.empty?

      # For hashes, we'll use the setter method for any field provided, but if
      # one wasn't provided, we'll set it to the default
      fields.each do |key,field|
        if arg.has_key?(key)
          send("#{key}=", arg[key])
        else
          default = field[:default]
          default = default.call(self) if default.respond_to?(:call)
          send("#{key}=", default, set_modified: false)
        end
      end
    else
      raise ArgumentError, "Unsupported argument type: #{arg.inspect}"
    end
  end

  # Return if this Component is unique per-Entity.
  #
  # Note, this method is replaced when the subclass calls #not_unique in it's
  # definition.
  def unique?
    true
  end

  # Return if this Component should be merged by Entity#merge
  #
  # Note: this method is replaced when the subclass calls Component.not_merged
  def merge?
    true
  end

  # Check if this Component should be saved
  def save?
    true  # replaced by Component.no_save()
  end

  # Return a Hash of field/value pairs
  def to_h
    self.class.fields.inject({}) do |o,(field,_)|
      o[field] = send(field)
      o
    end
  end

  # Return a Hash of the difference between this Component and another
  # Component of the same type, or a Hash with the same field keys
  def -(other)
    other = other.to_h if other.is_a?(self.class)
    raise ArgumentError, "Unsupported type for diff; #{other.inspect}" unless
        other.is_a?(Hash)
    to_h.reject { |k,v| other[k] == v }
  end

  # Clone a component
  def clone
    values = self.class.fields.map { |k,_| send(k) }
    self.class.new(values)
  end

  # Clear all modified flags on this instance.  Used in EntityManager after
  # merging all the base entities into a class.
  def clear_modified!
    self.class.fields.each do |k,_|
      begin
        remove_instance_variable("@__modified_#{k}")
      rescue NameError
      end
    end
    self
  end

  # Obscenely long name to try to not conflict with a possible field value, but
  # this will get a Hash containing field & modified value for every field in
  # this component that has been modified.
  def get_modified_fields
    self.class.fields.inject({}) do |out,(k,_)|
      out[k] = send(k) if instance_variable_get("@__modified_#{k}")
      out
    end
  end

  # Check if a field has been modified in this component.
  def field_modified?(name)
    instance_variable_get("@__modified_#{k}") == true
  end

  # Merge in another Component, or component values
  #
  # Arguments:
  #   other: Hash, or Component instance
  def merge!(other)
    other = other.get_modified_fields if other.is_a?(self.class)
    raise ArgumentError, "invalid other #{other.inspect}" unless
        other.is_a?(Hash)
    other.each { |k,v| send("#{k}=", v) }
  end

  # Hash this component instance for use in ruby eql? method
  def hash
    to_h.hash
  end

  # This instance equals another instance
  def ==(other)
    self.class == other.class && to_h == other.to_h
  end
  alias eql? ==

  # Get the value for a field.  Slower method created to support Script.
  def [](key)
    key = key.to_sym unless key.is_a?(Symbol)
    raise KeyError, "key not found: #{key}" unless
        self.class.fields.has_key?(key)
    send(key)
  end

  # []=
  #
  # Set the value for a field.  Slower than calling the setter directly.
  # Implemented to support Script.
  def []=(key, value)
    key = key.to_sym unless key.is_a?(Symbol)
    raise KeyError, "key not found: #{key}" unless
        self.class.fields.has_key?(key)
    send("#{key}=", value)
  end

  # Iterate through each field/value pair in the component.
  def each
    return enum_for(:each) unless block_given?
    self.class.fields.each { |name, _| yield name, send(name) }
  end
end
