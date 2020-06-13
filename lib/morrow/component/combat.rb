# Maintains all details about combat; added to an entity that is actively
# attacking another entity.
class Morrow::Component::Combat < Morrow::Component
  no_save

  # Entities attacking this target; may or may not be in the same room.  The
  # first element in this list will be attacked by this entity the next time
  # the combat system runs.
  field :attackers, type: [ :entity ], default: []
end
