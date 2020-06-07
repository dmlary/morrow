# This component holds configuration for a teleporter.  It is used by the
# teleporter script.
class Morrow::Component::Teleporter < Morrow::Component
  # destination of this teleporter'
  field :dest, type: :entity

  # Amount of time in seconds before the victim will be teleported.  This may
  # be a Range or a Numeric
  #
  # Examples:
  #   delay = 0       # teleport "immediately"
  #   delay = 0.25    # teleport "immediately" also, but as a Float
  #   delay = 10      # teleport in 10 seconds
  #   delay = 5..15   # teleport in a random number of seconds between 5 & 15
  #
  field :delay, type: Range, default: 10..10

  # message sent to character when they're moved
  field :to_entity, type: String

  # message sent to room when entity is moved
  field :to_room, type: String

  # run "look" after entity is moved
  field :look, type: :boolean, default: true
end
