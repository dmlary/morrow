# Used to track which entity this entity is within.  If an entity is moving, it
# first must be removed from the original location's Container component.
class Morrow::Component::Location < Morrow::Component

  # the entity (with a Container component) that this entity is inside
  field :entity, type: :entity
end
