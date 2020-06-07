# Spawn entities within this entity's ContainerComponent
class Morrow::Component::SpawnPoint < Morrow::Component

  # entities that have a SpawnComponent that will spawn here
  field :list, default: [], type: [ :entity ]
end
