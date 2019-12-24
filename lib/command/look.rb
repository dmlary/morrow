module Command::Look
  extend World::Helpers

  Command.register('look') do |actor, arg|
    loc = get_component(actor, LocationComponent) or
        fault "actor has no location", actor
    room = loc.entity

    show_contents = false

    target = case arg
      when nil, ""
        room
      when "self", "me"
        actor
      when /^in\s(.*?)$/
        show_contents = true
        match_keyword($1,
            visible_contents(actor: actor, cont: room),
            visible_contents(actor: actor, cont: actor))
      else
        match_keyword(arg,
            visible_exits(actor: actor, room: room),
            visible_contents(actor: actor, cont: room),
            visible_contents(actor: actor, cont: actor))
      end

    next "You do not see that here." unless target and
        viewable = get_component(target, ViewableComponent)

    return target.pretty_inspect if player_config(actor, :coder)

    case viewable.format
    when "room"
      show_room(actor, target)
    when "character"
      show_char(actor, target)
    when 'object'
      if show_contents
        show_contents(actor, target)
      else
        show_obj(actor, target)
      end
    else
      fault "look #{arg}", format, target
      "not implemented; look <thing>"
    end
  end

  class << self
    def show_room(actor, room)
      exits = room.get(:exits, :list).map do |p_ref|
        passage = p_ref.entity
        name = exit_name(passage)
        closed = passage.get(:closable, :closed)
        desc = (closed ? '[ &K%s&0 ]' : '%s') % name
        [ name, desc ]
      end.sort_by { |n,d| d }.map(&:last)

      title, desc = room.get(ViewableComponent, :short, :desc)

      buf = "&W%s&0\n" % title
      buf << desc
      buf << "\n"
      buf << "&WExits: &0%s&0" % exits.join(" ")
      buf << "\n"

      room.get(:container, :contents).each do |ref|
        entity = ref.entity
        next if entity == actor   # you can't see yourself in the room
        if long = entity.get(:viewable, :long)
          buf << long
          buf << "\n"
        end
      end

      buf
    end

    def show_char(actor, target)
      buf = ""
      buf << target.get(:viewable, :long)
      buf << "\n"

      # XXX short is a <RACE>
      # XXX He/She/They/It is in <CONDITION>
      buf << target.get(:viewable, :short)
      buf << " may be referred to as '&C%s&0'.\n" % keywords(target)

      # XXX equipment
    end

    def show_obj(actor, target)
      buf = ""
      if long = target.get(:viewable, :desc)
        buf << long
        buf << "\n" unless buf[-1] == "\n"
      end

      buf << target.get(:viewable, :short)
      buf << " may be referred to as '&C%s&0'.\n" % keywords(target)
    end

    def show_contents(actor, target)
      buf = ""
      buf << target.get(:viewable, :short)

      contents = target.get(:container, :contents) or
          return "#{buf} is not a container."

      return "#{buf} is closed." if target.get(:closable, :closed)

      if contents.empty?
        return buf << " is empty"
      end

      buf << ":\n"
      contents.each do |ref|
        if short = ref.entity.get(:viewable, :short)
          buf << "  "
          buf << short
          buf << "\n"
        end
      end
      buf
    end

  end
end
