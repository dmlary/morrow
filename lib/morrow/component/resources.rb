# Various resources for a character.
class Morrow::Component::Resources < Morrow::Component

  # Current health of this entity; may be higher than #health_max for due to
  # temporary hit points.
  field :health, type: Integer

  # Maximum health of this entity
  field :health_max, type: Integer
end
