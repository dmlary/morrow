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

  # Percentage of health_max that will be regenerated each second.
  field :health_regen, type: Float

  # position of the entity.  Affects ability to do specific commands,
  # resource regeneration, damage received.
  field :position, valid: %i{ standing sitting lying }, default: :standing

  # flag to denote the entity is unconscious, and unable to perform any
  # actions.
  field :unconscious, type: :boolean, default: false

  # Character's unmodified constitution.  Affects health, regeneration, and
  # constitution based saves.
  field :con_base, type: 3..30, default: 13

  # Any temporary modifiers to the character's constitution.  Capped at a +5
  # bonus.
  field :con_modifier, type: (-Float::INFINITY..5), default: 0
end
