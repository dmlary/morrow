# This component is added to an entity that will be teleported at a later
# time.  It is added by the teleporter script.
class Morrow::Component::Teleport < Morrow::Component
  # when this entity should be moved
  field :time, type: Time

  # The entity that scheduled this teleport; it will have a Teleporter
  # component.
  field :teleporter, type: :entity
end
