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
  field :words, type: [String], desc: 'Array of keywords'
end

class ContainerComponent < Component
  desc <<~DESC
    maintains a list of entities that are within this component.  Goes in
    Rooms, and Bags and Characters.
  DESC

  field :contents, default: [], type: [:entity],
      desc: 'Array of Entity IDs that reside within this Entity'
  field :max_volume, type: Integer, desc: 'Maximum volume of the container'
end

class LocationComponent < Component
  desc <<~DESC
    Tracks which entity this entity is inside.  If the location of an entity is
    going to change, this entity must first be removed from the old entity's
    ContainerComponent#contents Array.
  DESC

  field :entity, type: :entity, desc: 'Entity that this Entity is within'
end

class ViewableComponent < Component
  desc 'Entity is viewable within the world'

  field :format, freeze: true,
      valid: %w{ room object character extra_desc exit },
      desc: 'How the "look" command should show this entity'
  field :short, freeze: true, type: String,
      desc: 'char name, object name, room title'
  field :long, freeze: true, type: String,
      desc: 'object resting on the ground; npc standing'
  field :desc, freeze: true, type: String,
      desc: 'character, item, or room desc'
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
  field :revealed, default: false, valid: [ true, false ],
      desc: 'If this entity has been revealed in the room'
end

class ExitsComponent < Component
  desc 'Exits from a room; one for each cardinal direction'
  %w{ north south east west up down }.each do |dir|
    field dir, type: :entity, desc: "exit to the #{dir}"
  end
end

class EnvironmentComponent < Component
  desc <<~DESC
    Environmental details for a room/container.  These things impact the
    entities within the ContainerComponent.contents
  DESC

  field :terrain, valid: %i{ inside city field forest hills mountains
                             water_swim water_noswim air underwater
                             desert },
      default: :forest,
      desc: 'Type of terrain within a room'


  field :light, valid: 0..100, default: 100,
      desc: 'Amount of light in a room as a percent; not in use'

  field :flags, default: [], type: [Symbol],
      desc: 'unsupported flags imported from WBR'
end

class DestinationComponent < Component
  desc 'Where this Entity leads to, be it a room, or a portal'

  field :entity, type: :entity, desc: 'entity with a ContainerComponent'
end

class PlayerConfigComponent < Component
  desc 'Per-Player configuration data'

  field :color, default: false, valid: [ true, false ],
      desc: 'enable color output'
  field :coder, default: false, valid: [ true, false ],
      desc: 'enable coder output'
  field :compact, default: false, valid: [ true, false ],
      desc: 'enable compact output'
  field :send_go_ahead, default: false, valid: [ true, false ],
      desc: 'send telnet go-ahead codes'
end

class MetadataComponent < Component
  desc 'Loader hints used by EntityManager::Loader::* for use when saving'

  no_save
  field :source, freeze: true, type: String,
      desc: 'location from which this entity was loaded'
  field :area, freeze: true, type: String,
      desc: 'area to which this entity belongs'
  field :spawned_by, freeze: true, type: :entity,
      desc: 'entity with a SpawnComponent that create this entity'
  field :base, type: [:entity],
      desc: 'array of base entities on which this entity is built'
end

class ClosableComponent < Component
  desc 'Denote an Entity is closable/lockable and its current state'

  field :closable, default: true, valid: [ true, false ],
      desc: 'this entity can be closed'
  field :closed, default: true, valid: [ true, false ],
      desc: 'this entity is closed'
  field :lockable, default: false, valid: [ true, false ],
      desc: 'this entity can be locked'
  field :locked, default: false, valid: [ true, false ],
      desc: 'this entity is locked'
  field :pickable, default: true, valid: [ true, false ],
      desc: 'this entity can be unlocked with "pick", and similar abilities'
  field :key, type: :entity,
      desc: 'entity that can be used to unlock this entity'
end

class SpawnPointComponent < Component
  desc 'Spawn entities within this entity\'s ContainerComponent'
  field :list, default: [], type: [ :entity ],
    desc: 'entities that have a SpawnComponent that will spawn here'
end

class SpawnComponent < Component
  desc 'To schedule the spawning of an Entity within a container Entity'

  field :entity, type: :entity, desc: 'entity to be spawned'
  field :active, default: 0, type: Integer,
      desc: 'number of active entities spawned from point'
  field :min, default: 1, type: Integer,
      desc: 'minimum number present after spawning'
  field :max, default: 1, type: Integer,
      desc: 'maximum number that can be active at one time'
  field :frequency, default: 300, type: Numeric,
      desc: 'seconds between spawn events'
  field :next_spawn, type: Time,
      desc: 'next spawn event; Time instance'
end

class CommandQueueComponent < Component
  desc' Command queue for characters'

  no_save
  field :queue, clone: false, type: Thread::Queue,
      desc: 'Thread::Queue instance'
  field :blocked_until, type: Time,
      desc: 'Time that next command can be processed'
end

class ConnectionComponent < Component
  desc 'Connection for players'
  no_save
  field :conn, desc: 'TelnetServer::Connection instance'
  field :buf, default: '', type: String, desc: 'String of pending output'
end

class HookComponent < Component
  desc 'Used to run scripts when specific events occur in the world.'

  # due to compositing architecture, we're going to permit multiple hooks
  not_unique

  field :event, valid: %i{ will_enter on_enter will_exit on_exit },
      desc: <<~FIELD
    Event when this script should be run

    will_enter: Entity (entity) will be added to (dest) entity's
                ContainerComponent.  May be blocked by returning :deny.
                This hook will be called before the character performs 'look'
                in the dest room.

                Script arguments:
                  entity: Entity being moved
                  src:    entity's current location; may be nil
                  dest:   destination entity

    on_enter:   Entity (entity) has been added to (here) entity's
                ContainerComponent.
                This hook will be caled after the character performs 'look' in
                here.

                Script arguments:
                  entity: Entity that was added
                  here:   entity's current location

    will_exit:  Entity (entity) will removed from (src) entity's
                ContainerComponent.  May be blocked by returning :deny.
                Script arguments:

                  entity: Entity being moved
                  src:    entity's current location; may be nil
                  dest:   destination entity

    on_exit:    Entity (entity) has been removed from (here) entity's
                ContainerComponent.

                Script arguments:
                  entity: Entity that was removed
                  here:   entity's current location
  FIELD

  field :script, type: :entity,
      desc: 'entity containing the ScriptComponent to be run'

  field :script_config, type: Hash,
      desc: 'optional configuration for script'
end

class TeleporterComponent < Component
  desc <<~DESC
    This component holds configuration for a teleporter.  It is used by the
    teleporter script.

    XXX This should be changed into script arguments
  DESC

  field :dest, type: :entity, desc: 'destination of this teleporter'

  field :delay, default: 10,
      valid: proc { |v| [ Integer, Range, Float ].include?(v.class) },
      desc: 'delay before entity should be moved'

  field :look, default: true, valid: [ true, false ],
      desc: 'should the "look" command be run after teleport'
end

class TeleportComponent < Component
  desc <<~DESC
    This component is added to an entity that will be teleported at a later
    time.  It is added by the teleporter script.
  DESC

  field :dest, type: :entity, desc: 'where this entity should be moved to'

  field :time, type: Time, desc: 'when this entity should be moved'

  field :message, type: String,
      desc: 'message to display to character when they\'re moved'

  field :look, default: true, valid: [ true, false ],
      desc: 'run "look" after entity is moved'
end

class ScriptComponent < Component
  desc 'Component that holds a script'

  # Script instance
  field :script, clone: false, desc: 'script source code'
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
