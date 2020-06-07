# Denote an Entity is closable/lockable and its current state
class Morrow::Component::Closable < Morrow::Component

  # entity can be closed
  field :closable, type: :boolean, default: true, valid: [ true, false ]

  # entity is closed
  field :closed, type: :boolean, default: true, valid: [ true, false ]

  # entity can be locked
  field :lockable, type: :boolean, default: false, valid: [ true, false ]

  # entity is locked
  field :locked, type: :boolean, default: false, valid: [ true, false ]

  # entity can unlocked using the pick skill, and similar abilities
  field :pickable, type: :boolean, default: true, valid: [ true, false ]

  # entity that can be used to unlock this entity
  field :key, type: :entity
end
