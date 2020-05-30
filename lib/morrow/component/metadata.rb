# Various hints about where this entity came from.  Used for saving & spawn
# management.
class Morrow::Component::Metadata < Morrow::Component
  no_save

  # location from which this entity was loaded
  field :source, freeze: true, type: String

  # area to which this entity belongs
  field :area, freeze: true, type: String

  # entity with a SpawnComponent that create this entity
  field :spawned_by, freeze: true, type: :entity

  # array of base entities on which this entity is built
  field :base, type: [:entity]
end
