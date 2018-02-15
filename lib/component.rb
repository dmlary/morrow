require 'facets/hash/symbolize_keys'
require 'facets/hash/rekey'
require 'facets/hash/deep_rekey'

module Component
  RESERVED_KEYS = %i{ component inspect }

  class NotDefined < ArgumentError; end
  class AlreadyDefined < ArgumentError; end
  class TooManyValues < ArgumentError; end
  class InvalidKey < ArgumentError; end
  class ReservedKey < ArgumentError; end

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
      defaults = Hash[args.zip([])].merge(p).symbolize_keys

      reserved = defaults.keys & RESERVED_KEYS
      raise ReservedKey, reserved.join(", ") unless reserved.empty?

      klass = Class.new
      klass.include(InstanceMethods)
      klass.extend(ClassMethods)
      klass.instance_variable_set('@component', type)
      klass.instance_variable_set('@defaults', defaults)
      klass.instance_eval { attr_accessor *defaults.keys }
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
      raise NotDefined unless @components.has_key?(type)

      @components[type].new(*args)
    end
  end

  module ClassMethods
    attr_reader :component, :defaults

    def fields
      defaults.keys
    end

    def inspect
      '#<Component:%s %s>' % [ @component, @defaults.inspect ]
    end
  end

  module InstanceMethods
    # new(1,2,3,4)
    # new(1,2, field3: 3, field4: 4)
    def initialize(*values)

      # pull and set the default values
      defaults = self.class.defaults
      defaults.each { |k,v| instance_variable_set("@#{k}", v) }

      # pop off the parameters
      p = values.last.is_a?(Hash) ? values.pop : {}

      # Set our values based on argument index
      values.zip(defaults.keys).each do |value,key|
        raise TooManyValues, "failed on #{value.inspect}" if key.nil?
        instance_variable_set("@#{key}", value)
      end

      # Parameters have higher precident than arguments
      p.each do |key,value|
        key = "@#{key}"
        raise InvalidKey, key unless instance_variable_defined?(key)
        instance_variable_set(key, value)
      end
    end

    def component
      @__component ||= self.class.component
    end

    def component?
      true
    end

    def inspect
      state = instance_variables.map do |name|
          next if name[0,3] == '@__'
          "#{name}=" << instance_variable_get(name).inspect
        end.compact.join(' ')
      "#<Component:%s:0x%08x %s>" % [ component, __id__, state ]
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



