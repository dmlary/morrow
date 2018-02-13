require 'facets/module/is' # Module#is?

module Helpers::Attributes
  class Error < StandardError;end

  class UnsupportedConversionType < Error
    def initialize(value, type)
      @value = value
      @type = type
      super("unsupported conversion; #{value.inspect} => #{type}")
    end
  end

  class InvalidValue < Error
    def initialize(field, value, valid)
      @field = field
      @value = value
      @valid = valid
      super "invalid value for field %s: %s; valid values are: %s" %
          [ @field, @value.inspect, @valid,inspect ]
    end
  end

  class AttributeNotLoadable < Error
    def initialize(field, value)
      @field = field
      @value = value
      super "field %s is not loadable; set to %s" % [ field, value.inspect ]
    end
  end

  class << self

    def included(base)
      base.extend(ClassMethods)
      base.prepend(PrependMethods)

      # pull defaults from the super class if it also included Attributes
      defaults = base.superclass.is?(Helpers::Attributes) ?
          base.superclass.instance_variable_get('@attribute_defaults').clone :
          {}

      # set the defaults for this class
      base.instance_variable_set('@attribute_defaults', defaults)
    end

    def convert(value, type, p={})
      if value.is_a?(type)
        value
      elsif type == Symbol
        value.to_sym
      elsif type == String
        value.to_s
      elsif type == Range
        case value
        when /^(\d+)\.\.(\d+)/
          $1.to_i..$2.to_i
        when Array
          value.first..value.last
        else
          raise UnsupportedConversionType.new(value, type)
        end
      elsif type == Array
        Shellwords.split(value)
      else
        raise UnsupportedConversionType.new(value, type)
      end
    end
  end

  module ClassMethods

    # Arguments:
    #   ++name++ name of the attribute
    #   ++type++ data type for the attribute value
    #
    # Parameters:
    #   ++:setter++ custom proc to convert, validate & set value; false means
    #               no setter defined
    #   ++:valid++ valid values for attribute (checked via #include?)
    #   ++:default++ default value
    #   ++:lookup++ custom proc to convert argument to appropriate value
    #
    def attribute(name, type=String, p={})

      # Make life easier for callers who don't care about the type
      if type.is_a?(Hash)
        p = type
        type = String
      end

      # ensue they only used one of valid, lookup, or setter
      raise ArgumentError,
            ':valid, :lookup, and :setter are mutually exclusive' if
          (p.keys & %i{ valid lookup setter }).size > 1


      # build up our setter and supporting variables
      valid = p[:valid]
      lookup = p[:lookup]

      # set our default setter proc unless one has already been set
      p[:setter] = proc do |arg|
        value = lookup ? lookup.call(arg) : 
            Helpers::Attributes.convert(arg, type)

        raise InvalidValue.new(name, value, valid) if
            valid and !valid.include?(value)

        instance_variable_set("@#{name}", value)
      end unless p.has_key?(:setter)

      # set the setter unless it was set to false
      define_method("#{name}=", &p[:setter]) unless p[:setter] == false

      # add the getter
      attr_reader(name)

      # set the default value if provided
      @attribute_defaults[name] = p[:default] if p.has_key?(:default)
    end

    def set_default_values(instance)
      @attribute_defaults.each do |key,value|
        begin
          value = value.clone
        rescue TypeError
        end
        instance.instance_variable_set("@#{key}", value)
      end
    end
  end

  module PrependMethods
    def initialize(*args)
      self.class.set_default_values(self)
      super *args
    end
  end
end
