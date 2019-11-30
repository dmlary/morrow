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
    def define(type, *args)
      type = type.to_sym
      raise AlreadyDefined if @components.has_key?(type)

      # pop off any parameters
      p = args.last.is_a?(Hash) ? args.pop : {}

      # our defaults/fields are a hash of field & default value pairs.  For
      # arguments, we create a hash of field name (argument), and nil.  The
      # parameters are then merged into that hash, overriding any argument
      # fields that later had a default specified by parameter.
      defaults = Hash[args.zip([])].merge(p).symbolize_keys

      # Strip out the defaults that are References, these define the type of
      # entity this field will reference.
      refs = defaults.inject({}) do |out,(key,value)|
        next unless value.is_a?(Reference)
        out[key] = value
        defaults[key] = nil
        out
      end

      klass = Class.new
      klass.include(InstanceMethods)
      klass.extend(ClassMethods)
      klass.instance_variable_set('@type', type)
      klass.instance_variable_set('@defaults', defaults)
      klass.instance_variable_set('@refs', refs)
      @components[type] = klass
      klass
    end

    # load a number of component definitions
    def import(config)
      [ config ].flatten.each do |type|
        type = type.deep_rekey { |k| k.to_sym }
        define(type[:name], type[:fields] || {})
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
    attr_reader :type, :defaults, :refs

    def fields
      @defaults.keys
    end

    # return [Entity type(s), component] for a given reference field
    def ref(field)
      types, component = @refs.has_key?(field) ?
          @refs[field.to_sym].value : nil
      types = types.is_a?(Array) ? types : [types]
      types.map!(&:to_sym)
      [ types, component && component.to_sym ]
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
    # new(1,2, field3: 3, field4: 4)
    def initialize(*values)
      # pull some things from our class
      @type = self.class.type

      # manually deep-clone our values from the defaults
      @values = self.class.defaults.inject({}) do |h,(k,v)|
        h[k] = v.clone
        h
      end

      # pop off the parameters
      p = values.last.is_a?(Hash) ? values.pop : {}

      # Set our values based on argument index
      values.zip(@values.keys).each do |value,key|
        raise TooManyValues, "failed on #{value.inspect}" if key.nil?
        @values[key] = value
      end

      # Parameters have higher precident than arguments
      p.each { |field, value| set(field, value) }
    end
    attr_reader :type
    attr_accessor :entity_id

    def entity
      World.by_id(@entity_id)
    end

    # set(field=:value, value)
    def set(*args)
      field = (args.size == 1 ? :value : args.shift).to_sym
      value = args.first
      raise InvalidField, field unless @values.has_key?(field)
      @values[field] = value.is_a?(Entity) ? value.to_ref : value
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
  end
end

__END__

Datafile approach

Component.define('name', ...)     # => #<Component::Type>
Component.new('type', *values)    # => #<Component::Type:0x0000 ... >
Component.save(components.yml)    # => true
Component.load(components.yml)    # => true

components.yml:
---
- name: location
  value: !ruby/class 'EntityId'
- name: description
  value: !ruby/class 'String'
  default: 'empty description'
- name: health
  value:
    max: 1
    current: 1
- name: name
  value: !ruby/class 'String'
- name: keywords
  value: !ruby/class 'Array'
- name: contents
  value: !ruby/class 'Array'
- name: exit
  fields:
  - direction
  - location

templates.yml:
---
- name: character
  components:
  - health
  - description
  - keywords
  - contents
  - location
- name: player
  include:
  - character
  components:
  - name
  - title
  - password
- name: room
  components:
  - id
  - title
  - description
  - contents

player.yml
---
entity_type: player
components:
- health:
    max: 1000
    value: 20
- description: |
    Cross-eyed, and smelling faintly of rotten fish, Arbus appears to be lost in
    thought
- keywords: arbus
- name: arbus
- contents: []
- title: the damned
- password: seaworthy
- location: !entity/lookup 'room/1'

area/rooms.yml
---
- entity_type: room
  components:
  - id: 1
  - title: The Void
  - description: You are floating in nothing
  - exit:
      direction: north
      location: !entity/lookup 'room/1'
      ??? DOOR?!



