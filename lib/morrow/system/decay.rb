# System for making corpses decay
module Morrow::System::Decay
  extend Morrow::System

  class << self
    def frequency
      60
    end

    def view
      { all: :decay }
    end

    def update(corpse, decay)
      return if decay.at > now
      act(decay.act, actor: corpse) if decay.act

      # Get the room, it will be ok if this is nil
      room = entity_location(corpse)

      # Loop through the contents of the corpse trying to move the items to the
      # room.  If the move fails, just destroy the content items.
      entity_contents(corpse).each do |entity|
        move_entity(entity: entity, dest: room, force: true)
      rescue
        destroy_entity(entity)
      end

      destroy_entity(corpse)
    end
  end
end
