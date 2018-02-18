module System::CommandQueue
  extend System::Base

  World.register_system(:command_queue) do |entity, queue_comp|
    queue = queue_comp.value or next
    next if queue.empty?
    send_data(handle_command(entity, queue.shift), entity: entity)
    send_data("\n> ", entity: entity)
  end

  class << self

    def handle_command(entity, buf)
      return if buf.nil? or buf.empty?
  
      @entity = entity
      begin
        name, rest = buf.split(/\s+/, 2)
        method = 'command_' << name
        if respond_to?(method)
          send(method, rest)
        else
          "unknown command: #{name}\n"
        end
      ensure
        @entity = nil
      end
    end

    def not_implemented(buf="")
      "not implemented; " << buf
    end

    def command_look(target=nil)
      return not_implemented('look <target>') if target

      # pull the location the entity is in
      return "no location; entity=#{entity.inspect}\n" unless
          location_id = @entity.get_value(:location)

      # look up the room by entity id
      return "location entity not found; entity=#{@entity.inspect}\n" unless
          room = World.by_id(location_id)

      return room.pretty_inspect if @entity.get_coder(:config_options)

      exits = room.get(:exit, true).map(&:direction)
      exits = [ 'none' ] if exits.empty?

      buf = "&W%s&0\n" % room.get_value(:name)
      buf << room.get_value(:description)
      buf << "\n"
      buf << "&CExits: %s&0" % exits.join(" ")
      buf << "\n"

      # XXX need a safe way to pull all the entity ids from an array, map them
      # to entities, and provide an enumerator.  Also, if any entity id doesn't
      # resolve, throw a warning and remove the id from the array.
      room.get_value(:contents).each do |entity_id|
        entity = World.by_id(entity_id) or next
        next if entity == @entity
        if entity.has_component?(:long)
          buf << entity.get_value(:long)
          buf << "\n"
        elsif entity.type == :player
          buf << entity.get_value(:name)
          buf << " "
          buf << entity.get_value(:title)
          buf << "\n"
        else
          buf << entity.pretty_inspect
          buf << "\n"
        end
      end
      buf
    end

    def command_set(rest)
      return 'no configuration options found for this entity' unless
          config = @entity.get(:config_options)

      key, value = rest.split(/\s+/, 2) if rest
      if key
        return 'value must be true/false or on/off' unless
            value =~ /^(true|on|false|off)(\s|$)/
        value = %w{ true on }.include?($1) 
        config.send("#{key}=", value)
        return "#{key} = #{value}"
      end

      fields = config.class.fields
      field_width = fields.map(&:size).max
      buf = "&WConfigration Options:&0\n"
      fields.each do |name|
        buf << "  &W%#{field_width}s&0: &c%s&0\n" % [ name, config.send(name) ]
      end
      buf
    end

    def command_up(rest)
      room = get_room or return "unable to find what room you are in!"

      comp = room.get(:exit, true).find { |e| e.direction == 'up' } or
          return "There's no exit in that direction"

      next_room = World.by_id(comp.room_id) or return "Unknown room #{comp.inspect}"

      @entity.get(:location).value = next_room.id
      command_look
    end
  end
end
