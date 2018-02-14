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

    def define(type, *args)
      type = type.to_sym
      raise AlreadyDefined, type if @types.has_key?(type)

      p = args.last.is_a?(Hash) ? args.pop : {}
      out = OpenStruct.new(components: [], includes: [])
      out.components.push(*args.map(&:to_sym))
      out.components.push(*[p[:components]].flatten.compact.map(&:to_sym))
      out.includes.push(*[p[:include]].flatten.compact.map(&:to_sym))
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
    types -= components.map(&:component)

    # create all the components
    @components = types
        .uniq
        .map do |name|
      begin
        Component.new(name)
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
end
