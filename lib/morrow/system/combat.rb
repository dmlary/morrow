# System for performing rounds of combat.
#
# This System depends on an artifact of Morrow::EntityManager::View, where the
# order of entities in the view is the same as the order in which they had the
# component added.  What this means is that the system will always update the
# initiator of combat before the victim.
module Morrow::System::Combat
  extend Morrow::System

  class << self
    # This system will update every 3 seconds
    def frequency
      3
    end

    def view
      { all: :combat }
    end

    def update(actor, combat)
      if entity_dead?(actor)
        return
      elsif entity_mortally_wounded?(actor)
        act("&r%{actor} %{v:be} mortally wounded," +
            " and will die if not aided soon.&0", actor: actor)
        return
      elsif entity_incapacitated?(actor)
        act("&r%{actor} %{v:be} incapacitated," +
            " and will die slowly if not aided.&0", actor: actor)
        return
      elsif entity_unconscious?(actor)
        act("&r%{actor} %{v:be} stunned, but will regain consciousness.&0",
            actor: actor)
        return
      end

      target = combat.target
      room = entity_location(actor)

      unless entity_exists?(target) and entity_location(target) == room
        unless target = find_next_attacker(combat, room)
          debug("#{entity_short(actor)} exit combat")
          remove_component(actor, combat)
          return
        end

        combat.target = target
        debug("#{entity_short(actor)} target #{entity_short(target)}")
      end

      do_combat_round(actor: actor, target: target)

      # XXX if the victim is dead, and there are no other attackers, exit
      # combat now, instead of during the next round
    end

    private

    # Perform a round of combat by actor against target.
    #
    # By the time this is called, actor and target have been verified to both
    # exist, and be in the same room.
    def do_combat_round(actor:, target:)
      hit_entity(actor: actor, entity: target)
    end

    def find_next_attacker(combat, room)
      attackers = combat.attackers
      attackers.select! do |attacker|
        entity_location(attacker) == room
      rescue Morrow::UnknownEntity
        false
      end
      attackers.first
    end
  end
end
