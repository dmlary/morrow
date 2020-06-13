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
      # get the location of the combat
      unless room = entity_location(actor)
        remove_component(actor, :combat)
        raise Morrow::Error, "combat actor has no location: #{actor}"
      end

      # prune the attackers list of dead & fled entities
      combat.attackers.delete_if do |entity|
        entity_dead?(entity) or entity_location(entity) != room
      end

      # figure out how many attacks the actor gets
      attacks = char_attacks(actor)

      # Loop through attacking things as we can
      while attacks > 0 && target = combat.attackers.first

        # Handle all those states that prevent us from attacking
        if entity_dead?(actor)
          exit_combat(actor)
          return
        elsif entity_mortally_wounded?(actor)
          act("&r%{actor} %{v:be} mortally wounded," +
              " and will die if not aided soon.&0", actor: actor,
              to_actor: true)
          break
        elsif entity_incapacitated?(actor)
          act("&r%{actor} %{v:be} incapacitated," +
              " and will die slowly if not aided.&0", actor: actor,
             to_actor: true)
          break
        elsif entity_unconscious?(actor)
          act("&r%{actor} %{v:be} stunned, but will regain consciousness.&0",
              actor: actor, to_actor: true)
          break
        end

        # hit the target
        attacks -= 1
        hit_entity(actor: actor, entity: target)

        # the target may have died or fled, in which case we have to move on to
        # the next target
        combat.attackers.shift if entity_dead?(target) or
            entity_location(target) != room
      end

      exit_combat(actor) if combat.attackers.empty?
    end
  end
end
