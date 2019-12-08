module System::Spawner
  extend System::Base
  extend World::Helpers

  def self.spawn_entities(dest, sp)
    next_spawn = sp.next_spawn
    return unless next_spawn && Time.now >= next_spawn
    return if (active = sp.active) >= sp.max

    unless ref = sp.entity
      # remove the component so we don't get this error every 0.25 seconds
      dest.rem_component(sp)
      fault("No entity field in SpawnPointComponent; removed", dest, comp)
    end

    min = sp.min
    min = 1 if min.nil? or min < 0

    count = active >= min ? 1 : min - active
    count.times do
      spawn(dest, ref)
      active += 1
    end
    sp.active = active
    sp.next_spawn = Time.now + sp.frequency
  end

  World.register_system(:spawner, :spawn_point,
      method: method(:spawn_entities))
end
