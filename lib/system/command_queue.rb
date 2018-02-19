module System::CommandQueue
  extend System::Base
  extend World::Helpers

  World.register_system(:command_queue) do |actor, queue_comp|
    queue = queue_comp.get or next
    next if queue.empty?

    # run the command, which returns output
    buf = Command.run(actor, queue.shift)

    # append the prompt
    buf << "\n> "

    # send the actor the output
    send_data(buf, entity: actor)
  end

  class << self
    def command_set(rest)
      return 'no configuration options found for this entity' unless
          config = @entity.get_component(:config_options)

      key, value = rest.split(/\s+/, 2) if rest
      if key
        return 'value must be true/false or on/off' unless
            value =~ /^(true|on|false|off)(\s|$)/
        value = %w{ true on }.include?($1) 
        config.set(key, value)
        return "#{key} = #{value}"
      end

      fields = config.fields
      field_width = fields.map(&:size).max
      buf = "&WConfigration Options:&0\n"
      fields.each do |name|
        buf << "  &W%#{field_width}s&0: &c%s&0\n" % [ name, config.get(name) ]
      end
      buf
    end

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
