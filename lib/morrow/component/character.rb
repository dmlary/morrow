# Entity is a character in the world.  It can perform actions, has a level,
# some classes, etc.
class Morrow::Component::Character < Morrow::Component

  # Overall level of the character.  For players, this will be the maximum
  # level of all their classes.
  field :level, type: (1..), default: 1

  class_level_type = {
    _template: {
      keys: lambda { Morrow.config.classes.keys },
      type: 1..,
      desc: <<~DESC
        Level of the character for the given class.  A value of nil denotes
        that the character is not a member of the class.
      DESC
    }
  }
  # Per-class level for this character.
  field :class_level, type: class_level_type

  # Unmodified base health of this non-player character.  This value will be
  # nil for players, as their base health is calculated in char_health_base().
  field :health_base, type: Integer

  # Temporary modifications to the character's health.  Primarly from equipment
  # and spell affects.  This value is added to the base health of a character
  # to get their maximum health.
  field :health_modifier, type: Integer, default: 0

  # Maximum health of this entity.  This value is updated by
  # update_char_resources().
  field :health_max, type: Integer, default: 20

  # Current health of this entity; may be higher than #health_max for due to
  # temporary hit points.
  field :health, type: Integer, default: 20

  # Unmodified health regeneration rate for the character.  This is a
  # percentage of health_max that will be regenerated every second.
  field :health_regen_base, type: Float

  # Modifier to health_regen_base.  This is added to the health_regen_base to
  # set health_regen in update_char_regen()
  field :health_regen_modifier, type: Float, default: 0

  # Percentage of health_max that will be regenerated each second.
  field :health_regen, type: Float, default: 100.0/(5 * 60)

  # position of the entity.  Affects ability to do specific commands,
  # resource regeneration, damage received.
  field :position, valid: %i{ standing sitting lying }, default: :standing

  # flag to denote the entity is unconscious, and unable to perform any
  # actions.
  field :unconscious, type: :boolean, default: false

  # Character's unmodified strength.  Affects how much the character can carry.
  field :str_base, type: 3..30, default: 13

  # Any temporary modifiers to str_base; capped at +5 bonus
  field :str_modifier, type: (-Float::INFINITY..5), default: 0

  # Character's unmodified intelligence.
  field :int_base, type: 3..30, default: 13

  # Temporary modifiers to int_base; capped at +5 bonus.
  field :int_modifier, type: (-Float::INFINITY..5), default: 0

  # Character's unmodified wisdom.
  field :wis_base, type: 3..30, default: 13

  # Temporary modifiers to wis_base; capped at +5 bonus.
  field :wis_modifier, type: (-Float::INFINITY..5), default: 0

  # Character's unmodified dexterity
  field :dex_base, type: 3..30, default: 13

  # Temporary modifiers to dex_base; capped at +5 bonus.
  field :dex_modifier, type: (-Float::INFINITY..5), default: 0

  # Character's unmodified constitution.  Affects health, regeneration, and
  # constitution based saves.
  field :con_base, type: 3..30, default: 13

  # Any temporary modifiers to the character's constitution.  Capped at a +5
  # bonus.
  field :con_modifier, type: (-Float::INFINITY..5), default: 0

  # character's unmodified charisma.
  field :cha_base, type: 3..30, default: 13

  # Temporary modifiers to cha_base; capped at +5 bonus
  field :cha_modifier, type: (-Float::INFINITY..5), default: 0
end
