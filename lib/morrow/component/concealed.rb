# Entity has been concealed.  Used for hidden/secret doors.  Could also work
# for items and characters (hide).
#
# XXX Some time after being revealed, doors should reset.  Maybe in area reset
# code, or at reveal time, a timer is set to restore the concealed state.
class Morrow::Component::Concealed < Morrow::Component

  # If this entity has been revealed in the room
  field :revealed, type: :boolean, default: false, valid: [ true, false ]
end
