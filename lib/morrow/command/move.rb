module Morrow::Command::Move
  extend Morrow::Command

  dirs = Morrow::Helpers.exit_directions

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
      dest = exits[dir] or
          command_error('Alas, you cannot go that way ...')
      door = exits["#{dir}_door"]

      if door && entity_closed?(door)
        if entity_concealed?(door)
          command_error('Alas, you cannot go that way ...')
        else
          command_error("#{entity_short(door).capitalize} is closed.")
        end
      else
        error = move_entity(entity: actor, dest: dest, look: true)
        command_error('It\'s too crowded for you to fit.') if error
      end
    end
  end
end
