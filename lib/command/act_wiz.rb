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
end
