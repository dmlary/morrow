module System::Spawner
  extend System::Base
  extend World::Helpers

  def self.spawn_entities(dest, comp)
    next_spawn = comp.get(:next_spawn)
    return unless next_spawn == 0 || Time.now >= next_spawn
    return if (active = comp.get(:active)) >= comp.get(:max)

    unless ref = comp.get(:entity)
      # remove the component so we don't get this error every 0.25 seconds
      dest.rem_component(comp)
      fault("No entity field in spawn_point", dest, comp)
    end

    min = comp.get(:min)
    min = 1 if min.nil? or min < 0

    count = active >= min ? 1 : min - active
    count.times do
      spawn(dest, ref)
      active += 1
    end
    comp.set(:active, active)
    comp.set(:next_spawn, Time.now + comp.get(:frequency))
  end

  World.register_system(:spawner, :spawn_point,
      method: method(:spawn_entities))
end
