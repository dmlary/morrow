require_relative 'component'

# This Component is to mark those Entity instances that should not be visible
# to Systems via EntityManager::View.  This primarily applies to mob & object
# entities loaded from disk, and used as templates to spawn other Entity
# instances into the world.
class ViewExemptComponent < Component
  no_save
end

# Set of keywords a player may use to reference this Entity
class KeywordsComponent < Component
  field :words
end

# maintains a list of entities that are within this component.  Goes in Rooms,
# and Bags and Characters.
class ContainerComponent < Component
  field :contents, default: []    # Array of entity id's
  field :max_volume               # Maximum volume of the container
end

# Tracks which entity this entity is inside.  If the location of an entity is
# going to change, this entity must first be removed from the old entity's
# ContainerComponent#contents Array.
class LocationComponent < Component
  field :entity
end

# This Entity is viewable in the world
class ViewableComponent < Component
  field :format, freeze: true,
      valid: %w{ room object character extra_desc exit }
  field :short, freeze: true  # name, room title
  field :long, freeze: true   # object resting on the ground; mob standing
  field :desc, freeze: true   # character, item description; room desc
end

# Entity has been concealed.  Used for hidden/secret doors.  Could also work
# for items and characters (hide).
#
# XXX Some time after being revealed, doors should reset.  Maybe in area reset
# code, or at reveal time, a timer is set to restore the concealed state.
class ConcealedComponent < Component
  field :revealed, default: false, valid: [ true, false ]
end

# exits from a room, one per-cardinal direction
class ExitsComponent < Component
  %w{ north south east west up down }.each { |dir| field dir }
end

# Environmental details for a room/container.  These things impact the entities
# within the ContainerComponent.contents
class EnvironmentComponent < Component

  # The type of terrain within a room; we default to the forest because TREES!
  field :terrain, valid: %i{ inside city field forest hills mountains
                             water_swim water_noswim air underwater
                             desert }, default: :forest

  # Light level within the room, as a percent
  field :light, valid: proc { |v| (0..100).include?(v.to_i) }, default: 100

  # XXX unsupported flags imported from WBR
  field :flags, default: []
end

# Where this Entity leads to, be it a room, or a portal
class DestinationComponent < Component
  field :entity     # entity with a ContainerComponent
end

# Per-Player Configuration
class PlayerConfigComponent < Component
  field :color, default: false
  field :coder, default: false
  field :compact, default: false
  field :send_go_ahead, default: false
end

# Loader hints used by EntityManager::Loader::* for use when saving
class MetadataComponent < Component
  no_save
  field :source, freeze: true
  field :area, freeze: true
  field :spawned_by, freeze: true
  field :base
end

# Denote an Entity is closable/lockable and their current state
class ClosableComponent < Component
  field :closable, default: true
  field :closed, default: true
  field :lockable, default: false
  field :locked, default: false
  field :pickable, default: true
  field :key    # ref to key Entity
end

# Spawn entities within this entity's ContainerComponent
class SpawnPointComponent < Component
  field :list, default: []
end

# To schedule the spawning of an Entity within a container Entity
class SpawnComponent < Component
  field :entity               # entity to be spawned
  field :active, default: 0   # number of active entities spawned from point
  field :min, default: 1      # minimum number present after spawning
  field :max, default: 1      # maximum number that can be active at one time
  field :frequency, default: 300  # seconds between spawn events
  field :next_spawn               # next spawn event; Time instance
end

# Command queue for characters
class CommandQueueComponent < Component
  no_save
  field :queue, clone: false  # Queue instance
  field :blocked_until    # Time that next command can be processed
end

# Connection for players
class ConnectionComponent < Component
  no_save
  field :conn               # TelnetServer::Connection instance
  field :buf, default: ''   # String of pending output
end

### QUESTIONABLE COMPONENTS ###
class AffectComponent < Component
  not_unique
  field :component    # Component to which this affect applies
  field :field        # field in the component to which this affect applies
  field :type         # Affect type; :set, :delta, :push
  field :value        # value to use for affect
end
