module Morrow::Command::Move
  extend Morrow::Command

  dirs = Morrow.config.components[:exits].fields.keys

  help(%w{movement} + dirs, <<~HELP)
    Syntax: #{dirs.join(", ")}

    These commands are used to move from room to room in the world.
  HELP

  dirs.each do |dir|
    priority 100
    define_singleton_method(dir) do |actor,_|
      room = entity_location(actor) or
          fault("actor has not location: #{actor}")

      exits = get_component(room, :exits) or
          command_error('Alas, you cannot go that way ...')
      passage = exits[dir] or
          command_error('Alas, you cannot go that way ...')

      if entity_closed?(passage)
        if entity_concealed?(passage)
          command_error('Alas, you cannot go that way ...')
        else
          door = entity_short(passage) || entity_keywords(passage)
          command_error("The #{door} is closed.")
        end
      else
        dest = get_component(passage, :destination) or
            fault("passage #{passage} has no destination")
        error = move_entity(entity: actor, dest: dest.entity, look: true)
        command_error('It\'s too crowded for you to fit.') if error
      end
    end
  end
end
