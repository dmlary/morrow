# Schedules an entity to destroyed at a later time.
class Morrow::Component::Decay < Morrow::Component

  # time after which this entity will be destroyed
  field :at, type: Time

  # format string to send to Morrow::Helper.act when this entity is destroyed.
  # This entity will be the `actor` when act is called.
  field :act, type: String
end
