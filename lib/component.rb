require 'forwardable'
require 'facets/kernel/deep_clone'
require 'facets/hash/symbolize_keys'
require 'facets/hash/rekey'
require 'facets/hash/deep_rekey'

module Component
  class NotDefined < ArgumentError; end
  class AlreadyDefined < ArgumentError; end
  class TooManyValues < ArgumentError; end
  class InvalidField < ArgumentError; end

  @components ||= {}

  class << self
    def types
      @components.keys
    end

    # wipe all known component types
    def reset!
      @components.clear
    end

    # define a component type
    def define(type, fields: {}, unique: true)
      raise ArgumentError, "fields must be a Hash" unless fields.is_a?(Hash)
      type = type.to_sym
      raise AlreadyDefined if @components.has_key?(type)

      klass = Class.new
      klass.include(InstanceMethods)
      klass.extend(ClassMethods)
      klass.instance_variable_set('@type', type)
      klass.instance_variable_set('@defaults', fields)
      klass.instance_variable_set('@unique', unique)
      @components[type] = klass
      klass
    end

    # load a number of component definitions
    def import(config)
      [ config ].flatten.each do |type|
        type = type.deep_rekey { |k| k.to_sym }
        type[:unique] = true unless type.has_key?(:unique)
        type[:fields] ||= {}
        define(type[:name], fields: type[:fields], unique: type[:unique])
      end
      self
    end

    # export all known components
    def export
      @components.map do |name,klass|
        h = { 'name' => name.to_s }
        h['fields'] = klass.defaults.rekey { |k| k.to_s }
        h
      end
    end

    # allocate an instance of a specific type of component
    def new(type, *args)
      type = type.to_sym
      raise NotDefined, type unless @components.has_key?(type)

      @components[type].new(*args)
    end
  end

  module ClassMethods
    attr_reader :type, :defaults

    def fields
      @defaults.keys
    end

    def unique?
      !!@unique
    end

    def inspect
      '#<Component:%s %s>' % [ @type, @defaults.inspect ]
    end
  end

  module InstanceMethods
    extend Forwardable

    def savable?
      false
    end

    # new(1,2,3,4)
    # new(field: 1, field2: 2, ...)
    def initialize(arg=nil)
      # pull some things from our class
      @type = self.class.type

      @array_fields = []
      @modified = Set.new     # keep track of which fields have been modified

      # manually deep-clone our values from the defaults
      @values = self.class.defaults.inject({}) do |h,(k,v)|
        @array_fields << k if v.is_a?(Array)
        h[k] = v.clone
        h
      end

      case arg 
      when Hash
        arg.each { |field, value| set(field, value.clone) }
      when Array
        # Set our values based on argument index
        arg.zip(@values.keys).each do |value,key|
          raise TooManyValues, "failed on #{value.inspect}" if key.nil?
          set(key, value.clone)
        end
      when nil
        # noop; no arguments.  If the caller wants to set a single field
        # component to nil, they can use Hash, Array args, or call set
        # directly.
      else
        set(arg.clone)
      end
    end
    attr_reader :type
    attr_accessor :entity_id

    def clone
      # deep cloning will happen in Component#initialize
      Component.new(@type, @values)
    end

    def entity
      World.by_id(@entity_id)
    end

    # set(field=:value, value)
    def set(*args)
      field = (args.size == 1 ? @values.keys.first : args.shift).to_sym
      raise InvalidField, field unless @values.has_key?(field)
      @modified << field

      value = args.first
      value = value.ref if value.is_a?(Entity)

      if @array_fields.include?(field)
        @values[field].push(*value)
      else
        @values[field] = value
      end
      self
    end

    def get(field=:value)
      field = field.to_sym
      raise InvalidField, field unless @values.has_key?(field)
      value_or_ref = @values[field]

      value_or_ref.is_a?(Reference) ?
          value_or_ref.resolve(self.entity) :
          value_or_ref
    end

    def fields
      @values.keys
    end

    def values
      @values.values
    end

    def unique?
      self.class.unique?
    end

    # return a hash of which fields have been modified from the defaults for
    # this component
    def changed_fields
      defaults = self.class.defaults
      @values.reject { |k,v| v == defaults[k] }
    end

    def_delegator :@values, :each_pair

    def component?
      true
    end

    def inspect
      state = @values.map { |k,v| "#{k}=#{v.inspect}" }.join(' ')
      "#<Component:%s:0x%08x %s>" % [ type, __id__, state ]
    end

    def encode_with(coder)
      coder.tag = nil
      coder[type.to_s] = begin
        if @values.empty?
          nil
        elsif @values.size == 1
          @values.first.last
        else
          @values.deep_rekey { |k| k.to_s }.reject { |k| k =~ /_id$/ }
        end
      end
    end

    def modified_fields
      @modified.inject({}) { |o,k| o[k] = @values[k]; o }
    end
  end
end
