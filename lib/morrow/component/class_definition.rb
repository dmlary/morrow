# Attributes for a character
class Morrow::Component::ClassDefinition < Morrow::Component
  # name of the class
  field :name

  # abbreviated name for the class
  field :short_name

  # health to gain for each level in this class.
  field :health_per_level, type: Integer, default: 15

  # health regeneration modifier provided by the class
  field :health_regen_mod, type: Float, default: 0
end
