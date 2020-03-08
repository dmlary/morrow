# Maintains all details about combat; added to an entity that is actively
# attacking another entity.
class Morrow::Component::Combat < Morrow::Component
  no_save

  # Target of the entity's attacks
  field :target, type: :entity

  # Entities attacking this target; may or may not be in the same room
  field :attackers, type: [ :entity ], default: []
end
