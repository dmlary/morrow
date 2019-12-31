module Command::Movement
  extend World::Helpers

  World::CARDINAL_DIRECTIONS.each do |dir|
    Command.register(dir, priority: 1000) do |actor|
      traverse_passage(actor, dir)
    end
  end

  class << self
    def traverse_passage(actor, name)
      room = entity_location(actor) or
          fault "no current location", actor

      exits = get_component(room, :exits) or
          return "Alas, you cannot go that way...\n"
      passage = exits.send(name)

      if passage.nil?
        "Alas, you cannot go that way...\n"
      elsif entity_closed?(passage)
        if entity_concealed?(passage)
          "Alas, you cannot go that way...\n"
        else
          "The path #{name} seems to be closed.\n"
        end
      else
        dest = get_component(passage, :destination) or
            fault "passage #{passage} has no destination!"
        move_entity(entity: actor, dest: dest.entity, look: true)
      end
    end
  end
end
