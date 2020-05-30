module Morrow
  class Function::Sandbox

    def initialize(entity: nil, component: nil, field: nil, level: nil)
      @entity = entity
      @component = component
      @field = field
      @level = level
    end

    # get the level of the entity
    def level
      @level || Helpers.char_level(@entity)
    end

    # get the value for this field from the base entity
    def base 

      # we're going to create a new entity from the base entities of this
      # entity.  We'll then patch up the base of that entity to point at the
      # grandparent bases, so that we can safely iterate up the entity
      # ancestry.
      bases = Helpers.entity_base(@entity)
      b = Helpers.create_entity(base: bases)
      Helpers.get_component!(b, :metadata).base =
          bases.map { |b| Helpers.entity_base(b) }.flatten.compact

      begin
        value = Helpers.get_component!(b, @component)[@field]

        value.is_a?(Morrow::Function) ?
            value.call(entity: b, component: @component, field: @field,
                level: @level) :
            value
      ensure
        Morrow.em.destroy_entity(b)
      end
    end

    # get a value from the range based on the level of the entity.
    #
    # Examples:
    #   # level 1 entity, will get the minimum
    #   sandbox = Sandbox.new(some_level_1_entity)
    #   sandbox.by_level(13..30, max_at: 65)    # =>  13
    #
    #   # level 65 entity, will get the maximum
    #   sandbox = Sandbox.new(some_level_65_entity)
    #   by_level(13..30, max_at: 65)            # =>  60
    #
    def by_level(range, max_at:)
      level >= max_at ? range.last :
          range.first + (((range.size - 1)/max_at.to_f)*level).to_i
    end
  end
end
