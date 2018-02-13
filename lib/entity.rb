class Entity
  class TypeNotDefined < ArgumentError; end
  class TypeAlreadyDefined < ArgumentError; end

  @templates ||= {}

  class << self
    def types
      @templates.keys
    end

    def reset!
      @templates.clear
    end

    # define(:room, :title, :description)
    # define(:room, components: [:title, :description ])
    # define(:player, :password, include: :character)
    def define(type, *args)
      type = type.to_sym
      raise TypeAlreadyDefined if @templates.has_key?(type)

      @templates[type] = Template.new(*args)
    end

    def get(type)
      @templates[type] or raise TypeNotDefined, type
    end
  end

  class Template
    def initialize(*args)
      p = args.last.is_a?(Hash) ? args.pop : {}
      @components = []
      @components.push(*args)
      @components.push(*[p[:components]].flatten) if p.has_key?(:components)
      @include = p.has_key?(:include) ? [ p[:include] ].flatten : []
    end

    def new(base=nil)
      base ||= Entity.new
      @include.each do |name|
        Entity.get(name).new(base)
      end
      @components.each { |n| base << Component.new(n) }
      base
    end
  end

  def initialize(*components)
    @components = components
  end

  def add(*components)
    @components.push(*components)
  end
  alias << add
end
