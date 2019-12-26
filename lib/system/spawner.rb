module System::Spawner
  extend System::Base
  extend World::Helpers

  def self.view
    @view ||= World.get_view(all: SpawnPointComponent)
  end

  def self.update(dest, point)
    point.list.each do |spawn_entity|
      spawn = get_component(spawn_entity, SpawnComponent) or next

      active = spawn.active
      next if active >= spawn.max

      # skip this one if either the next_spawn time hasn't hit, or we have at
      # least the minimum entities active
      next_spawn = spawn.next_spawn
      next if next_spawn && next_spawn > Time.now && active >= spawn.min

      entity = spawn_at(dest: dest, base: spawn.entity)
      get_component!(entity, :metadata).spawned_by = spawn_entity
      spawn.active = active += 1

      if active < spawn.max
        spawn.next_spawn ||= Time.now
        spawn.next_spawn += spawn.frequency
      else
        # once we've hit the maximum, clear the next spawn time.  This will be
        # reset in World::Helpers.destroy_entity().
        spawn.next_spawn = nil
      end
    end
  end
end
