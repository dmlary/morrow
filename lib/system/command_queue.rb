module System::CommandQueue
  extend World::Helpers

  def self.view
    @view ||= World.get_view(all: CommandQueueComponent)
  end

  def self.update(actor, queue_comp)
    queue = queue_comp.queue or return
    return if queue.empty?

    # run the command; it may return output for the character
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

    # command handled all output; just return
    return if buf.nil?

    unless buf.is_a?(String)
      error "command returned non-String; actor=%s command='%s'" %
          [ entity_keywords(actor), cmd ]

      buf = (player_config(actor, :coder) ? buf.inspect :
          "error in command; logged to admin")
    end

    send_to_char(char: actor, buf: buf)
  end
end
