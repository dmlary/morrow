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

      room = entity_location(corpse) or
          warn 'decaying entity %s has no location; destroying contents' %
              [ corpse ]

      entity_contents(corpse).each do |entity|
        room ? move_entity(entity: entity, dest: room) :
            destroy_entity(entity)
      end

      destroy_entity(corpse)
    end
  end
end
