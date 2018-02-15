require 'ostruct'

class Entity
  class NotDefined < ArgumentError; end
  class AlreadyDefined < ArgumentError; end
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

  def initialize(type, *components)
    p = components.last.is_a?(Hash) ? components.pop : {}

    raise NotDefined, type unless template = Entity.get(type)
    @type = type.to_sym
    @tag = p[:tag]

    # recursively include components from included types
    seen = []
    types = []
    visit = template.includes.clone
    while included_type = visit.pop
      next if seen.include?(included_type)
      seen << included_type

      included_template = Entity.get(included_type) or
          raise NotDefined,
              'type=%s; included from %s' % [ included_type, @type ]

      visit.unshift(*included_template.includes)
      types.push(*included_template.components)
    end

    # add the components added by this template
    types.push(*template.components)

    # trim the types for any component types that were provided
    provided = components.map(&:component)
    types.delete_if { |type,_| provided.include?(type) }

    # create all the components
    @components = types
        .uniq
        .map do |type_and_defaults|
      begin
        Component.new(*type_and_defaults)
      rescue Component::NotDefined
        raise Component::NotDefined,
            'type=%s; included from %s' % [ name, @type ]
      end
    end
    
    # append any supplied components
    @components.push(*components.flatten)
  end
  attr_reader :type, :components, :tag

  def add(*components)
    @components.push(*components)
    self
  end
  alias << add
  alias id __id__

  def get(component, multiple=false)
    if multiple == false
      component = component.to_sym
      @components.find { |c| c.component == component }
    elsif component.is_a?(Array)
      @components.select { |c| component.include?(c.component) }
    else
      component = component.to_sym
      @components.select { |c| c.component == component }
    end
  end

  def has_component?(type)
    !!@components.find { |c| c.component == type }
  end

  def method_missing(name, *args, &block)
    return super unless name =~ /^get_(.*)$/
    method = $1
    comp = get(*args)
    comp ? comp.send(method) : nil
  end
end
