require_relative 'component'

module Morrow

# This component is added to entities that should not be acted upon by most
# systems.
class TemplateComponent < Component
  no_save
end

class KeywordsComponent < Component
  desc 'A set of keywords a player may use to reference this Entity'
  field :words, type: [String], desc: 'Array of keywords'
end

class ContainerComponent < Component
  desc <<~DESC
    maintains a list of entities that are within this component.  Goes in
    Rooms, Items (Bags) and Characters.
  DESC

  field :contents, default: [], type: [:entity],
      desc: 'Array of Entity IDs that reside within this Entity'

  field :max_volume, type: Numeric, desc: <<~DESC
    Maximum volume of this container.

    When set for a room, this limits the number of characters & items that can
    fit within the room.

    When set for an item, this limits the number of items that can fit inside.

    When set on a character, this limits the number of items they can carry.

    The volume of an entity is stored in CorporealComponent.volume
  DESC

  field :max_weight, type: Numeric, desc: <<~DESC
    Maximum weight this container can hold.

    Primarily used on a character, to limit how much they can carry by weight.
  DESC

  field :on_enter, desc: <<~DESC
    Script to run when an Entity is added to :contents.

    Script is called with the following parameters:
      here:   this Entity
      entity: Entity being moved
  DESC
end

class LocationComponent < Component
  desc <<~DESC
    Tracks which entity this entity is inside.  If the location of an entity is
    going to change, this entity must first be removed from the old entity's
    ContainerComponent#contents Array.
  DESC

  field :entity, type: :entity, desc: 'Entity that this Entity is within'
end

# Denotes the visibility of the component in the world, and which of it's
# peer Components are visible to 'look'.
#
# | type | short | long | desc | contents | exits | keywords |
# | ---- | ----- | ---- | ---- | -------- | ----- | -------- |
# | room | yes   | nil  | yes  | :long    | true  | false    |
# | char | yes   | yes  | yes  | nil      | false | true     |
# | obj  | yes   | yes  | yes  | :short   | false | true     |
# | extra| nil   | nil  | yes  | nil      | false | false    |
# | exit | yes   | nil  | yes  | nil      | false | false    |
#
class ViewableComponent < Component
  desc 'Entity is viewable within the world'

  field :short, freeze: true, type: String,
      desc: 'char name, object name, room title'
  field :long, freeze: true, type: String,
      desc: 'object resting on the ground; npc standing'
  field :desc, freeze: true, type: String,
      desc: 'character, item, or room desc'

  # Formatter to use when looked at.
  field :formatter, type: String, valid: %s{ room obj char exit desc_only }

  # Container contents are viewable
  field :contents, type: :boolean, default: false
end

class AnimateComponent < Component
  desc <<~DESC
    This Entity is animated.  Representing any sort of player or non-player
    character.  Anything that can move on it's own, perform actions, etc.
  DESC
end

class CorporealComponent < Component
  desc <<~DESC
    This component is added to entities that have physical substance within the
    world.
  DESC

  field :height, type: Numeric,
      desc: 'Height; just for flavor at the moment.'

  field :weight, type: Numeric, default: 0, desc: <<~DESC
    Weight of the Entity.  Should be updated to include the sum weight of its
    contents if the Entity also has a ContainerComponent.
  DESC

  field :volume, type: Numeric, default: 0, desc: <<~DESC
    Total volume this Entity takes up inside a ContainerComponent.
  DESC
end

# XXX Some time after being revealed, doors should reset.  Maybe in area reset
# code, or at reveal time, a timer is set to restore the concealed state.
class ConcealedComponent < Component
  desc <<~DESC
    Entity has been concealed.  Used for hidden/secret doors.  Could also work
    for items and characters (hide).
  DESC
  field :revealed, type: :boolean, default: false, valid: [ true, false ],
      desc: 'If this entity has been revealed in the room'
end

class EnvironmentComponent < Component
  desc <<~DESC
    Environmental details for a room/container.  These things impact the
    entities within the ContainerComponent.contents
  DESC

  field :terrain,
      desc: 'Type of terrain within a room',
      type: Symbol,
      valid: %i{ inside city field forest hills mountains
                 water_swim water_noswim air underwater
                 desert },
      default: :forest

  field :light, type: Integer, valid: 0..100, default: 100,
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

  field :color, type: :boolean, default: false, valid: [ true, false ],
      desc: 'enable color output'
  field :coder, type: :boolean, default: false, valid: [ true, false ],
      desc: 'enable coder output'
  field :compact, type: :boolean, default: false, valid: [ true, false ],
      desc: 'enable compact output'
  field :send_go_ahead, type: :boolean, default: false, valid: [ true, false ],
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

  field :closable, type: :boolean, default: true, valid: [ true, false ],
      desc: 'this entity can be closed'
  field :closed, type: :boolean, default: true, valid: [ true, false ],
      desc: 'this entity is closed'
  field :lockable, type: :boolean, default: false, valid: [ true, false ],
      desc: 'this entity can be locked'
  field :locked, type: :boolean, default: false, valid: [ true, false ],
      desc: 'this entity is locked'
  field :pickable, type: :boolean, default: true, valid: [ true, false ],
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
  field :frequency, default: 300, type: Integer,
      desc: 'seconds between spawn events'
  field :next_spawn, type: Time,
      desc: 'next spawn event; Time instance'
end

class InputComponent < Component
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

  # pending output buffer; will be sent by Morrow::System::Connection
  field :buf, default: '', type: String, desc: 'String of pending output'

  # Last time any input was received on this connection; updated by whichever
  # server is handling conn.
  field :last_recv, type: Time
end

class TeleporterComponent < Component
  desc <<~DESC
    This component holds configuration for a teleporter.  It is used by the
    teleporter script.

    XXX This should be changed into script arguments
  DESC

  field :dest, type: :entity, desc: 'destination of this teleporter'

  field :delay, type: Range, default: 10..10, desc: <<~DESC
    Amount of time in seconds before the victim will be teleported.  This may
    be a Range or a Numeric

    Examples:
      delay = 0       # teleport "immediately"
      delay = 0.25    # teleport "immediately" also, but as a Float
      delay = 10      # teleport in 10 seconds
      delay = 5..15   # teleport in a random number of seconds between 5 & 15
  DESC

  field :to_entity, type: String,
      desc: 'message sent to character when they\'re moved'

  field :to_room, type: String,
      desc: 'message sent to room when entity is moved'

  field :look, type: :boolean, default: true, valid: [ true, false ],
      desc: 'run "look" after entity is moved'
end

class TeleportComponent < Component
  desc <<~DESC
    This component is added to an entity that will be teleported at a later
    time.  It is added by the teleporter script.
  DESC

  field :time, type: Time, desc: 'when this entity should be moved'

  field :teleporter, type: :entity, desc: <<~DESC
    The entity that scheduled this teleport.  It will have a
    TeleporterComponent.
  DESC
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

# Help documents are also entities, we store the details of the help in this
# component.
class HelpComponent < Component
  # body of the help document
  field :body
end
end

require_relative 'component/exits.rb'
