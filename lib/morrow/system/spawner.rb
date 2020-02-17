# Spawn system is responsible for servicing SpawnPoints to create new entities
# throuhgout the world.
module Morrow::System::Spawner
  extend Morrow::System

  class << self
    def view
      { all: :spawn_point }
    end

    def update(dest, point)
      point.list.each do |spawn_entity|
        spawn = begin
          get_component(spawn_entity, :spawn)
        rescue Morrow::UnknownEntity => ex
          point.list.delete(spawn_entity)
          warn 'unknown entity (%s) in spawn_point.list for %s; removed' %
              [ spawn_entity, dest ]
          next
        end

        active = spawn.active
        next if active >= spawn.max

        # skip this one if either the next_spawn time hasn't hit, or we have at
        # least the minimum entities active
        next_spawn = spawn.next_spawn
        next if next_spawn && next_spawn > now && active >= spawn.min

        entity = spawn_at(dest: dest, base: spawn.entity)
        get_component!(entity, :metadata).spawned_by = spawn_entity
        spawn.active = active += 1

        if active < spawn.max
          spawn.next_spawn ||= now
          spawn.next_spawn += spawn.frequency
        else
          # once we've hit the maximum, clear the next spawn time.  This will
          # be reset in World::Helpers.destroy_entity().
          spawn.next_spawn = nil
        end
      end
    end
  end
end
