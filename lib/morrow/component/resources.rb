# Various resources for a character.
class Morrow::Component::Resources < Morrow::Component
  TYPES = %i{health}

  # Current health of this entity; may be higher than #health_max for due to
  # temporary hit points.
  field :health, type: Integer

  # Maximum health of this entity.  This is a function of multiple fields in
  # the Attributes component.
  field :health_max, type: Integer

  # Percentage of health_max that will be regenerated each second.
  field :health_regen, type: Float
end
