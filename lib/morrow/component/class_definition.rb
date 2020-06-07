# Attributes for a character
class Morrow::Component::ClassDefinition < Morrow::Component
  # name of the class
  field :name

  # abbreviated name for the class
  field :short_name

  # function used to calculate the health of a character with this class at a
  # given level.
  field :health, type: Morrow::Function

  # health regeneration modifier provided by the class
  field :health_regen, type: Morrow::Function
end
