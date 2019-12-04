module Command::ActWiz
  extend World::Helpers

  Command.register('spawn', help: <<~HELP) do |actor, arg=nil|
    Usage: spawn <virtual>

    Spawn an Entity in the current room based off <virtual>.
  HELP
    entity = begin
      entity = spawn(actor.get(:location), arg)
      "You wave your hand and #{entity.get(:viewable, :short)} appears."
    rescue EntityManager::UnknownVirtual
      "Entity not found: #{arg}"
    end

  end
end
