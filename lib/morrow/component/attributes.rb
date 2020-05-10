# Attributes for a character
class Morrow::Component::Attributes < Morrow::Component

  # This field denotes that the attributes have been updated recently, and
  # changes need to be propigated out to other components for this character.
  field :updated, type: :boolean

  # Base maximum health of this character with no adjustments.  Will be changed
  # by gaining levels.  This value feeds into Resources#health_max.
  field :health_base, type: Integer

  # Temporary adjustments to the maximum health of this character.  Altered by
  # spell affects, equipment, and the like.  This value feeds into
  # Resources#health_max.
  field :health_mod, type: Integer

  # Base health regeneration as a percentage of maximum health regenerated per
  # second for this character with no adjustments.  This value is unlikely to
  # change, but may change at specific levels for certain classes.
  #
  # This value feeds into Resources#health_regen using the following formula:
  #     Resources#health_regen =
  #          health_regen_multiplier * ( health_regen_base + health_regen_mod )
  #
  # Default is based off a character standing idle for 12 minutes would
  # be at full health.
  field :health_regen_base, type: Float, default: 100.0/(12*60)

  # Temporary adjustments to the health regeneraton rate of this character.
  # This value is changed based on spell affects, and equipment.  This value
  # feed into Resources#health_regen.
  #
  # This value feeds into Resources#health_regen using the following formula:
  #     Resources#health_regen =
  #          health_regen_multiplier * ( health_regen_base + health_regen_mod )
  field :health_regen_mod, type: Float, default: 0

  # Health regeneration multiplier.  Most often modified by character position,
  # and combat status.
  # This value feeds into Resources#health_regen using the following formula:
  #     Resources#health_regen =
  #          health_regen_multiplier * ( health_regen_base + health_regen_mod )
  field :health_regen_multiplier, type: Float, default: 1.0
end
