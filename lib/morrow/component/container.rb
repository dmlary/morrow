# List of entities that are held within this component.  Added to rooms, bags,
# characters.
class Morrow::Component::Container < Morrow::Component

  # Array of entities that are contained in this entity.
  field :contents, default: [], type: [:entity]

  # Maximum volume of this container.
  # 
  # When set for a room, this limits the number of characters & items that can
  # fit within the room.
  # 
  # When set for an item, this limits the number of items that can fit inside.
  # 
  # When set on a character, this limits the number of items they can carry.
  # 
  # The volume of an entity is stored in Corporeal.volume
  field :max_volume, type: Numeric

  # Maximum weight this container can hold.
  # 
  # Primarily used on a character, to limit how much they can carry by weight.
  field :max_weight, type: Numeric

  # Script to run when an Entity is added to :contents.
  # 
  # Script is called with the following parameters:
  #   here:   this Entity
  #   entity: Entity being moved
  field :on_enter
end
