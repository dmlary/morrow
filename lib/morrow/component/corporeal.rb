# This component is added to entities that have physical substance within the
# world.
class Morrow::Component::Corporeal < Morrow::Component

  # height, used for flavor at the moment.
  field :height, type: Numeric

  # Weight of the entity.  Does not include the weight of any contents inside
  # if this entity is a container.
  field :weight, type: Numeric, default: 0

  # volume this entity takes up within a container.
  field :volume, type: Numeric, default: 0
end
