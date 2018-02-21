module System::CommandQueue
  extend System::Base
  extend World::Helpers

  World.register_system(:command_queue) do |actor, queue_comp|
    queue = queue_comp.get or next
    next if queue.empty?

    # run the command, which returns output
    buf = begin
      Command.run(actor, queue.shift)
    rescue Command::SyntaxError => ex
      "syntax error: %s\n" % ex.message
    end

    # append the prompt
    buf << "\n> "

    # send the actor the output
    send_data(buf, entity: actor)
  end

  class << self
    def command_up(rest)
      room = get_room or return "unable to find what room you are in!"

      comp = room.get_component(:exit, true)
          .find { |e| e.get(:direction) == 'up' } or
              return "There's no exit in that direction"

      move_to_location(@entity, comp.get(:room_id))
      command_look
    end
  end
end
