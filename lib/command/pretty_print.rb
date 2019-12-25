module Command::PrettyPrint
  extend World::Helpers

  Command.register('pp', help: <<~HELP) do |actor, target=nil|
    Usage: pp [entity]

    Pretty-print a given entity, or the current room.
  HELP
    target ||= entity_location(actor)

    comps = World.entities[target] or next "Entity not found: #{target}"

    buf = { entity: target, components: comps.compact }.pretty_inspect
    buf = CodeRay.scan(buf, :ruby).term if player_config(actor, :color)

    buf
  end
end
