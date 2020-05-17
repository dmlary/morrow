# Attributes for a character
class Morrow::Component::ClassDefinition < Morrow::Component
  # name of the class
  field :name

  # abbreviated name for the class
  field :short_name

  # mathematical function used to calculate the health of a character with this
  # class at a given level.
  field :health_func, type: Morrow::Function

  # health regeneration modifier provided by the class
  field :health_regen_mod, type: Float, default: 0
end
