module Command::Movement
  extend World::Helpers

  World::CARDINAL_DIRECTIONS.each do |dir|
    Command.register(dir, priority: 1000) do |actor|
      traverse_passage(actor, dir)
    end
  end

  class << self
    def traverse_passage(actor, name)
      location = get_component(actor, LocationComponent) or
          fault "no current location", actor

      passage = match_keyword(name,
          visible_exits(actor: actor, room: location.entity))

      if passage.nil?
        "Alas, you cannot go that way...\n"
      elsif entity_closed?(passage)
        "The path #{name} seems to be closed.\n"
      else
        dest = get_component(passage, :destination) or
            fault "passage #{passage} has no destination!"
        move_entity(actor, dest.entity)
        Command::Look.show_room(actor, dest.entity)
      end
    end
  end
end
