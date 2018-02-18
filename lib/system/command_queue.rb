module System::CommandQueue
  extend System::Base

  World.register_system(:command_queue) do |entity, queue_comp|
    queue = queue_comp.get or next
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

      # get room for the actor
      return "entity location not found; entity=#{@entity.inspect}\n" unless
          room = get_room(@entity)

      return room.pretty_inspect if @entity.get(:config_options, :coder)

      exits = room.get_component(:exit, true).map { |e| e.get(:direction) }
      exits = [ 'none' ] if exits.empty?

      buf = "&W%s&0\n" % room.get(:name)
      buf << room.get(:description)
      buf << "\n"
      buf << "&CExits: %s&0" % exits.join(" ")
      buf << "\n"

      # XXX need a safe way to pull all the entity ids from an array, map them
      # to entities, and provide an enumerator.  Also, if any entity id doesn't
      # resolve, throw a warning and remove the id from the array.
      room.get(:contents).each do |entity_id|
        entity = World.by_id(entity_id) or next
        next if entity == @entity
        if entity.has_component?(:long)
          buf << entity.get(:long)
          buf << "\n"
        elsif entity.type == :player
          buf << entity.get(:name)
          buf << " "
          buf << entity.get(:title)
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
