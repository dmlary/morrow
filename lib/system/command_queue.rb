class System::CommandQueue < System::Base
  def update(entities)
    entities.each do |entity|
      queue = entity.get_value(:command_queue) or next
      next if queue.empty?
      handle_command(entity, queue.shift)
      prompt(entity)
    end
  end

  def prompt(entity)
    send_data(entity, "\n")
    send_data(entity, "> ")
  end

  def handle_command(entity, buf)
    return if buf.empty?

    name, rest = buf.split(/\s+/, 2)
    method = 'command_' << name
    if respond_to?(method)
      send(method, entity, rest)
    else
      send_data(entity, "unknown command: #{name}\n")
    end
  end

  def command_raise(entity, target=nil)
    raise RuntimeError, entity
  end

  def command_look(entity, target=nil)
    if target
      send_data(entity, "not implemented; target=#{target.inspect}\n")
      return
    end

    # pull the location the entity is in
    unless location_id = entity.get_value(:location)
      send_data(entity, "no location; entity=#{entity.inspect}\n")
      return
    end

    # look up the room by entity id
    unless room = World.by_id(location_id)
      send_data(entity,
          "location entity not found; entity=#{entity.inspect}\n")
      return
    end

    send_data(entity, "&W%s&0\n" % room.get_value(:title))
    send_data(entity, room.get_value(:description) + "\n")
    send_data(entity, "&CExits: &0")
    send_data(entity, "\n")
  end

  def command_set(entity, rest)
    key, value = rest.split(/\s+/, 2) if rest

    unless config = entity.get(:config_options)
      send_data(entity, "config_options not found; entity=#{entity.inspect}\n")
      return
    end

    fields = config.class.fields
    field_width = fields.map(&:size).max
    if key.nil?
      send_data(entity, "&WConfigration Options:&0\n")
      fields.each do |name|
        send_data(entity,
            "  &W%#{field_width}s&0: &c%s&0\n" % [ name, config.send(name) ])
      end
      return
    end

    send_data(entity, 'Not implemented')
  end
end
