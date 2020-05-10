# Entity is animated.  Representing any sort of player or non-player character.
# Anything that can move on it's own, perform actions, fight back, etc.
class Morrow::Component::Animate < Morrow::Component
  # position of the entity.  Affects ability to do specific commands,
  # resource regeneration, damage received.
  field :position, valid: %i{ standing sitting lying }, default: :standing

  # flag to denote the entity is unconscious, and unable to perform any
  # actions.
  field :unconscious, type: :boolean, default: false
end

