# Attributes for a character
class Morrow::Component::Attributes < Morrow::Component

  field :con_base, type: Integer
  field :con_mod, type: Integer

  # snapshotting?  No, because some changes may need to be permanent.
  # Changes:
  # * max resource
  # * regen?  Calculated from class levels, con, position
  # * attributes
  # * spell/special affects
  #
  # Looking for an **easily** reversable method for applying modifiers to
  # any component/field.
  #
  # calculate max hp:
  #   (hp[druid] + hp[shifter])/2 * total_levels * (1 + (con - 12)/100) +
  #     bonus hp * multiplier?
  #
  # When does max hp get recalculated?
  # * level gained
  # * con changes
  # * bonus hp changes
  # * hp multiplier changes (do we need this?  could be fun.)
  #
  # hp_base: hp[classes]/n_classes * total_levels * con_bonus * racial bonus
  # hp_mod: 0
  # hp_multiplier: 0  # con_bonus should not affect hp_mod
  #
  # What does this look like in usage?
  # * level gained/lost
  #   * update_entity_resources()
  # * item equiped/removed
  #   * update_entity_resources()
  # * spell affect applied/removed
  #   * update_entity_resources()
  #
  # calculate regen:
  #   (1 + racial_regen_bonus + average(class_regen_bonus))
  #   racial regen * average(class regen rate) 
  #


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
