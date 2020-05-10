# To schedule the spawning of an Entity within a container Entity
class Morrow::Component::Spawn < Morrow::Component

  # entity to be spawned
  field :entity, type: :entity

  # number of active entities spawned from point
  field :active, default: 0, type: Integer

  # minimum number present after spawning
  field :min, default: 1, type: Integer

  # maximum number that can be active at one time
  field :max, default: 1, type: Integer

  # seconds between spawn events
  field :frequency, default: 300, type: Integer

  # next spawn event; Time instance
  field :next_spawn, type: Time
end
