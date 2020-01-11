require_relative 'component'

class ViewExemptComponent < Component
  desc <<~DESC
    This Component is to mark those Entity instances that should not be visible
    to Systems via EntityManager::View.  This primarily applies to mob & object
    entities loaded from disk, and used as templates to spawn other Entity
    instances into the world.
  DESC
  no_save
end

class KeywordsComponent < Component
  desc 'A set of keywords a player may use to reference this Entity'
  field :words
end

class ContainerComponent < Component
  desc <<~DESC
    maintains a list of entities that are within this component.  Goes in
    Rooms, and Bags and Characters.
  DESC

  field :contents, default: []    # Array of entity id's
  field :max_volume               # Maximum volume of the container
end

class LocationComponent < Component
  desc <<~DESC
    Tracks which entity this entity is inside.  If the location of an entity is
    going to change, this entity must first be removed from the old entity's
    ContainerComponent#contents Array.
  DESC

  field :entity
end

class ViewableComponent < Component
  desc 'Entity is viewable within the world'

  field :format, freeze: true,
      valid: %w{ room object character extra_desc exit }
  field :short, freeze: true  # name, room title
  field :long, freeze: true   # object resting on the ground; mob standing
  field :desc, freeze: true   # character, item description; room desc
end

# This Entity is animated.  Representing any sort of player or non-player
# character.  Anything that can move on it's own, perform actions, etc.
class AnimateComponent < Component
  desc <<~DESC
    This Entity is animated.  Representing any sort of player or non-player
    character.  Anything that can move on it's own, perform actions, etc.
  DESC
end

# XXX Some time after being revealed, doors should reset.  Maybe in area reset
# code, or at reveal time, a timer is set to restore the concealed state.
class ConcealedComponent < Component
  desc <<~DESC
    Entity has been concealed.  Used for hidden/secret doors.  Could also work
    for items and characters (hide).
  DESC
  field :revealed, default: false, valid: [ true, false ]
end

class ExitsComponent < Component
  desc 'Exits from a room; one for each cardinal direction'
  %w{ north south east west up down }.each { |dir| field dir }
end

class EnvironmentComponent < Component
  desc <<~DESC
    Environmental details for a room/container.  These things impact the
    entities within the ContainerComponent.contents
  DESC

  # The type of terrain within a room; we default to the forest because TREES!
  field :terrain, valid: %i{ inside city field forest hills mountains
                             water_swim water_noswim air underwater
                             desert }, default: :forest

  # Light level within the room, as a percent
  field :light, valid: proc { |v| (0..100).include?(v.to_i) }, default: 100

  # XXX unsupported flags imported from WBR
  field :flags, default: []
end

class DestinationComponent < Component
  desc 'Where this Entity leads to, be it a room, or a portal'

  field :entity     # entity with a ContainerComponent
end

class PlayerConfigComponent < Component
  desc 'Per-Player configuration data'

  field :color, default: false
  field :coder, default: false
  field :compact, default: false
  field :send_go_ahead, default: false
end

class MetadataComponent < Component
  desc 'Loader hints used by EntityManager::Loader::* for use when saving'

  no_save
  field :source, freeze: true
  field :area, freeze: true
  field :spawned_by, freeze: true
  field :base
end

class ClosableComponent < Component
  desc 'Denote an Entity is closable/lockable and its current state'

  field :closable, default: true
  field :closed, default: true
  field :lockable, default: false
  field :locked, default: false
  field :pickable, default: true
  field :key    # ref to key Entity
end

class SpawnPointComponent < Component
  desc 'Spawn entities within this entity\'s ContainerComponent'
  field :list, default: []
end

class SpawnComponent < Component
  desc 'To schedule the spawning of an Entity within a container Entity'

  field :entity               # entity to be spawned
  field :active, default: 0   # number of active entities spawned from point
  field :min, default: 1      # minimum number present after spawning
  field :max, default: 1      # maximum number that can be active at one time
  field :frequency, default: 300  # seconds between spawn events
  field :next_spawn               # next spawn event; Time instance
end

class CommandQueueComponent < Component
  desc' Command queue for characters'

  no_save
  field :queue, clone: false  # Queue instance
  field :blocked_until    # Time that next command can be processed
end

class ConnectionComponent < Component
  desc 'Connection for players'
  no_save
  field :conn               # TelnetServer::Connection instance
  field :buf, default: ''   # String of pending output
end

#
class HookComponent < Component
  desc 'Used to run scripts when specific events occur in the world.'

  # due to compositing architecture, we're going to permit multiple hooks
  not_unique

  # Event when this script should be run
  #
  # will_enter: Entity (entity) will be added to (dest) entity's
  #             ContainerComponent.  May be blocked by returning :deny.
  #             This hook will be called before the character performs 'look'
  #             in the dest room.
  #
  #             Script arguments:
  #               entity: Entity being moved
  #               src:    entity's current location; may be nil
  #               dest:   destination entity
  #
  # on_enter:   Entity (entity) has been added to (here) entity's
  #             ContainerComponent.
  #             This hook will be caled after the character performs 'look' in
  #             here.
  #
  #             Script arguments:
  #               entity: Entity that was added
  #               here:   entity's current location
  #
  # will_exit:  Entity (entity) will removed from (src) entity's
  #             ContainerComponent.  May be blocked by returning :deny.
  #             Script arguments:
  #
  #               entity: Entity being moved
  #               src:    entity's current location; may be nil
  #               dest:   destination entity
  #
  # on_exit:    Entity (entity) has been removed from (here) entity's
  #             ContainerComponent.
  #
  #             Script arguments:
  #               entity: Entity that was removed
  #               here:   entity's current location
  field :event, valid: %i{ will_enter on_enter will_exit on_exit }

  # This points at the entity id for the script that should be run
  field :script

  # Optional configuration for :script.
  field :script_config
end

# XXX this should probably be changed into script arguments
class TeleporterComponent < Component
  desc <<~DESC
    This component holds configuration for a teleporter.  It is used by the
    teleporter script.
  DESC

  # destination entity
  field :dest

  # delay before entity should be moved
  field :delay, default: 10,
      valid: proc { |v| [ Integer, Range, Float ].include?(v.class) }

  # should character look after teleport
  field :look, default: true, valid: [ true, false ]
end

class TeleportComponent < Component
  desc <<~DESC
    This component is added to an entity that will be teleported at a later
    time.  It is added by the teleporter script.
  DESC

  # destination entity
  field :dest, valid: proc { |v| v.nil? or World.entity_exists?(v) }

  # Time at which they should be teleported
  field :time

  # message displayed to the character when they're teleported.  Message is
  # displayed before 'look' output.
  field :message

  # should character look after teleport
  field :look, default: true, valid: [ true, false ]
end

class ScriptComponent < Component
  desc 'Component that holds a script'

  # Script instance
  field :script, clone: false
end

### QUESTIONABLE COMPONENTS ###
class AffectComponent < Component
  desc 'affects; not reall in use yet'

  not_unique
  field :component    # Component to which this affect applies
  field :field        # field in the component to which this affect applies
  field :type         # Affect type; :set, :delta, :push
  field :value        # value to use for affect
end
