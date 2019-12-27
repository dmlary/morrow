module Command::PrettyPrint
  extend World::Helpers

  Command.register('pp', help: <<~HELP) do |actor, target=nil|
    Usage: pp [entity]

    Pretty-print a given entity, or the current room.
  HELP
    location = entity_location(actor)
    target ||= location

    unless entity_exists?(target)
      entities = []

      if cont = get_component(location, :container)
        entities.push(*cont.contents)
      end
      if cont = get_component(actor, :container)
        entities.push(*cont.contents)
      end
      entities.push(*World.entities.keys)
      target = match_keyword(target, entities)
    end

    comps = World.entities[target] or next "Entity not found: #{target}"

    buf = { entity: target, components: comps.compact }.pretty_inspect
    buf = CodeRay.scan(buf, :ruby).term if player_config(actor, :color)

    buf
  end
end
