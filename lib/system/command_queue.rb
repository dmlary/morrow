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

    send_data(entity, room.get_value(:title) + "\n")
    send_data(entity, room.get_value(:description) + "\n")
    send_data(entity, "Exits: ")
    send_data(entity, "\n")
  end
end
