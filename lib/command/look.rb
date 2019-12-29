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
            visible_contents(actor: actor, cont: room),
            visible_exits(actor: actor, room: room),
            visible_contents(actor: actor, cont: actor))
      end

    next "You do not see that here." unless target and
        viewable = get_component(target, ViewableComponent)

    next { entity: target,
        components: World.entities[target].compact }.pretty_inspect if
        player_config(actor, :coder)

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
    when 'extra_desc'
      viewable.desc
    when 'exit'
      viewable.desc
    else
      fault "look #{arg}", actor, viewable, target
      "not implemented; look <thing>"
    end
  end

  class << self
    def show_room(actor, room)
      exits = get_autoexits(room)
      view = get_component(room, ViewableComponent)
      title = view.short
      desc = view.desc

      buf = '&W%s&0' % title
      buf << ' [&c%s&0]' % room
      buf << "\n"
      buf << desc
      buf << "\n"
      buf << "&WExits: &0%s&0" % exits
      buf << "\n"

      visible_contents(actor: actor, cont: room).each do |entity|
        next if entity == actor   # you can't see yourself in the room
        view = get_component(entity, ViewableComponent)
        if view.long
          buf << view.long
          buf << "\n"
        end
      end

      buf
    end

    def show_char(actor, target)
      view = get_component(target, ViewableComponent)
      buf = ""
      if view.desc
        buf << view.desc
        buf << "\n"
      end

      # XXX short is a <RACE>
      # XXX He/She/They/It is in <CONDITION>
      buf << view.short
      buf << ' [&c%s&0]' % target
      buf << " may be referred to as '&C%s&0'.\n" % entity_keywords(target)

      # XXX equipment
    end

    def show_obj(actor, target)
      view = get_component(target, ViewableComponent)
      buf = ""
      if view.desc
        buf << view.desc
        buf << "\n" unless buf[-1] == "\n"
      end

      buf << view.short
      buf << ' [&c%s&0]' % target
      buf << " may be referred to as '&C%s&0'.\n" % entity_keywords(target)
    end

    def show_contents(actor, target)
      view = get_component(target, ViewableComponent)
      buf = ""
      buf << view.short
      buf << ' [&c%s&0]' % target

      container = get_component(target, ContainerComponent) or
          return "#{buf} is not a container."
      contents = container.contents

      return "#{buf} is closed." if entity_closed?(target)

      if contents.empty?
        return buf << " is empty"
      end

      buf << ":\n"
      contents.each do |entity|
        if short = entity_short(entity)
          buf << "  "
          buf << short
          buf << ' [&c%s&0]' % entity
          buf << "\n"
        end
      end
      buf
    end

    # get_autoexits
    #
    # construct the string shown by autoexit when looking at a room
    def get_autoexits(room)
      return 'none!' unless exits_comp = get_component(room, :exits)

      buf = exits_comp.to_h.inject('') do |out,(dir, entity)|
        next out if entity.nil?
        closed = entity_closed?(entity)
        next out if closed and entity_concealed?(entity)
        out << (closed ? '[ &K%s&0 ] ' : '%s ') % dir
      end

      buf.empty? ? 'none!' : buf
    end
  end
end
