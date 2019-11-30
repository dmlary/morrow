module System::CommandQueue
  extend System::Base
  extend World::Helpers

  World.register_system(:command_queue, :command_queue) do |actor, queue_comp|
    queue = queue_comp.get or next
    next if queue.empty?

    # run the command, which returns output
    cmd = queue.shift
    buf = begin
      Command.run(actor, cmd)
    rescue Command::SyntaxError => ex
      "syntax error: %s\n" % ex.message
    rescue Exception => ex
      World.exceptions.push(ex)
      error "command failed; actor=#{actor}, command=#{cmd}"
      Helpers::Logging.log_exception(ex)
      "error in command; logged to admin\n"
    end

    unless buf.is_a?(String)
      error "command returned non-String; actor=%s command='%s'" %
          [ actor.get(:keywords).inspect, cmd ]
            
      buf = (actor.get(:player_config, :coder) ? buf.inspect :
          "error in command; logged to admin\n")
    end

    buf << "\n" unless buf[-1] == "\n"
    buf << "\n" unless actor.get(:player_config, :compact)
    # append the prompt
    buf << "> "
    buf << "\xff\xf9" if actor.get(:player_config, :send_go_ahead)

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
