class Morrow::Component::Abilities < Morrow::Component

  class << self
    # The schema for all abilities in this component.  It is shared among all the
    # fields, which means updating this will update the schema for all of the
    # abilities.  This is useful for expanding the resources, or adding a new
    # type of ability.
    attr_reader :ability_type

    def add_ability(name)
      field(name.to_sym, type: @ability_type)
    end
  end

  @ability_type = {
    type: {
      desc: 'Type of ability; skill, spell, etc.',
      type: %i{ skill spell talent },
    },
    passive: {
      desc: 'Denotes this ability is a passive ability; example second attack.',
      type: :boolean,
    },
    proficiency: {
      desc: 'How well the entity knows this ability as a percent.',
      type: Numeric,
    },
    proficiency_mod: {
      desc: <<~DESC,
        Temporary modifiers to the entity's proficiency with this ability.  Can
        be the result of spell affects, or equipment.
      DESC
      type: Numeric,
    },
    proficiency_max: {
      desc: 'Maximum proficiency of this ability for this entity as a percent.',
      type: Numeric,
    },
    difficulty: {
      desc: <<~DESC,
        How difficult it is for the entity to improve this ability.  Expressed
        as a multiplier of base difficulty.  0.0 means the entity gets the
        ability for free, 1.0 means it's normal difficulty, 2.0 means it's
        double the difficulty.
      DESC
      type: 0..3.0,
    },
    cost: {
      desc: <<~DESC,
        Cost to use the ability.
      DESC
      type: {
        mana: {
          desc: 'mana cost of this ability',
          type: 0..,
        },
        health: {
          desc: 'health cost of this ability',
          type: 0..,
        },
        movement: {
          desc: 'movement cost of this ability',
          type: 0..,
        },
      },
    },
  }

  %i{ second_attack dodge }.each do |name|
    add_ability(name)
  end
end
