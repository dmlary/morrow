require_relative 'component'

# This Component is to mark those Entity instances that should not be visible
# to Systems via EntityManager::View.  This primarily applies to mob & object
# entities loaded from disk, and used as templates to spawn other Entity
# instances into the world.
class ViewExemptComponent < Component
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
  field :format, freeze: true   # formatting hint, :room, :object, :character
  field :short, freeze: true  # name, room title
  field :long, freeze: true   # object resting on the ground; mob standing
  field :desc, freeze: true   # character, item description; room desc
end

# List of exits from the current Entity (room)
class ExitsComponent < Component
  field :list, default: []    # Array of Refs to Entities with
                              # DestinationComponent
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
  field :queue, clone: false  # Queue instance
  field :blocked_until    # Time that next command can be processed
end

# Connection for players
class ConnectionComponent < Component
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
