module Command::ActWiz
  extend World::Helpers

  Command.register('spawn', help: <<~HELP) do |actor, arg=nil|
    Usage: spawn <entity>

    Spawn an entity in the current room by <virtual>.
  HELP
    entity = begin
      entity = spawn_at(dest: entity_location(actor), base: arg)
      "You wave your hand and #{entity_short(entity)} appears."
    rescue EntityManager::UnknownId
      "Entity not found: #{arg}"
    end

  end

  Command.register('goto', help: <<~HELP) do |actor, arg=nil|
    Usage: goto <entity|keyword>

    Go to something
  HELP
    next "goto <entity>" if arg.empty?
    next "entity not found: #{arg}" unless entity_exists?(arg)

    loc = get_component(arg, :location) and dest = loc.entity
    dest ||= arg
    move_entity(entity: actor, dest: dest)
    Command.run(actor, 'look')
  end
end
