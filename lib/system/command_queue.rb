module System::CommandQueue
  extend System::Base
  extend World::Helpers

  World.register_system(:command_queue,
      all: [ CommandQueueComponent ]) do |id, comp|
    queue = comp.queue or next
    next if queue.empty?

    actor = World.by_id(id)

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

    coder, compact, send_ga = actor.get(PlayerConfigComponent,
        :coder, :compact, :send_go_ahead)

    unless buf.is_a?(String)
      error "command returned non-String; actor=%s command='%s'" %
          [ actor.get(:keywords, :words).inspect, cmd ]
            
      buf = (coder ? buf.inspect : "error in command; logged to admin")
    end

    buf << "\n" unless buf[-1] == "\n"
    buf << "\n" unless compact
    # append the prompt
    buf << "> "
    buf << "\xff\xf9" if send_ga

    # send the actor the output
    send_data(buf, entity: actor)
  end
end
