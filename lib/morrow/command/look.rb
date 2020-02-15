module Morrow::Command::Look
  extend Morrow::Command

  class << self

    # Examine the world around you
    #
    # Syntax: look, look <character>, look <item>, look self, look in <item>
    #
    def look(actor, arg)
      room = entity_location(actor) or fault("actor has no location: #{actor}")
      into = false

      dir, target = get_component(room, :exits)&.each&.find do |dir, dest|
        dir.to_s.start_with?(arg)
      end if arg

      target ||= case arg
        when nil, ''
          room
        when 'self', 'me'
          actor
        when /^\s*in\s(.*?)$/
          into = true
          match_keyword($1,
              visible_contents(actor: actor, cont: room),
              visible_contents(actor: actor, cont: actor))
        else
          match_keyword(arg,
              visible_contents(actor: actor, cont: room),
              visible_exits(actor: actor, room: room),
              visible_contents(actor: actor, cont: actor))
        end

      command_error 'You do not see that here.' unless dir or
          (target and viewable = get_component(target, :viewable))

      out = ''

      formatter = dir ? :exit : (into ? :into : viewable.formatter.to_sym)

      case formatter
      when :into
        command_error 'You cannot look into that.' unless viewable.contents
        command_error 'It is closed.' if entity_closed?(target)

        out << "&W%s&0:\n" % viewable.short
        out << format_contents(actor, target, :short)

      when :room
        out << "&W%s&0\n" % viewable.short
        out << "%s\n" % viewable.desc
        out << format_exits(target)
        out << format_contents(actor, target, :long)

      when :char, :obj
        out << "%s\n" % viewable.desc if viewable.desc
        out << "%s may be referred to as '&W%s&0'." %
            [ viewable.short, entity_keywords(target) ]

      when :exit
        # patch up direction for better output
        dir = case dir
            when :up, :down
              "#{dir}ward"
            else
              "to the #{dir}"
            end

        command_error "You look #{dir}, but see nothing special." unless target

        out << format_exit(dir: dir, passage: target, actor: actor)
      else
        out << "%s\n" % viewable.desc
      end

      send_to_char(char: actor, buf: out)
    end

    private

    # return a String representing what a given actor sees when looking at a
    # specific exit.
    def format_exit(dir:, passage:, actor:)
      door = entity_keywords(passage)

      if closable = get_component(passage, :closable)
        if closable.closed
          if entity_concealed?(passage)
            "You look #{dir}, but see nothing special."
          else
            "The #{door} #{dir} is closed."
          end
        else
          "The #{door} #{dir} is open."
        end
      else
        dir = 'upward' if dir == :up
        "You can travel #{dir}."
      end
    end

    # return a String describing the contents of an entity
    #
    # @param actor [String] entity looking inside the container
    # @param target [String] entity that is being looked inside; has a
    #   container component
    # @param method [Symbol] viewable component field to show for each
    #   entity in the target
    # @return [String] human-readable contents of the target entity
    def format_contents(actor, target, method)
      command_error('%s is not a container.' % entity_short(target)) unless
          entity_container?(target)

      command_error('%s is closed.' % entity_short(target)) if
          entity_closed?(target)

      buf = visible_contents(actor: actor, cont: target)
          .inject('') do |out,entity|
        next out if entity == actor or
            !line = get_component(entity, :viewable)[method]
        out << "&%s%s&0\n" % [ entity_animate?(target) ? 'C' : 'c', line ]
      end

      buf.empty? ? 'It is empty.' : buf
    end

    # construct the string shown by autoexit when looking at a room
    def format_exits(room)
      buf = ''

      if exits = get_component(room, :exits)
        exits.to_h.each do |dir, dest|
          next unless dest
          closed = entity_closed?(dest)
          next if closed and entity_concealed?(dest)
          buf << (closed ? '[ %s ] ' : '%s ') % dir
        end
      end

      buf = 'none!' if buf.empty?

      "&WExits: %s&0\n" % buf
    end
  end
end
