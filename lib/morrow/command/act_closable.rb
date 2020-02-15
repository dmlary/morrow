module Morrow::Command::ActClosable
  extend Morrow::Command

  class << self
    # Open something in the world
    #
    # Syntax: open <door>, open <container>
    #
    def open(actor, arg=nil)
      command_error 'What would you like to open?' if arg.nil? || arg.empty?

      target = match_keyword(arg, closable_entities(actor)) or
          command_error 'You do not see that here.'

      comp = get_component(target, :closable)
      command_error 'It is locked.' if comp.locked
      command_error 'It is already open.' if !comp.closed

      comp.closed = false

      desc = entity_short(target) || "the #{entity_keywords(target)}"

      send_to_char(char: actor, buf: 'You open %s.' % desc)
    end

    # close something in the world
    #
    # Syntax: close <door>, close <container>
    #
    def close(actor, arg=nil)
      return "Close what?\n" if arg.nil? || arg.empty?

      target = match_keyword(arg, closable_entities(actor)) or
          return "Unable to find anything named '#{arg}' to close."

      comp = get_component(target, :closable)
      return "It is already closed." if comp.closed

      comp.closed = true
      return "You close #{entity_short(target) || arg}"
    end

    private

    def closable_entities(actor)
      room = entity_location(actor)  or fault "actor has no location", actor
      [ entity_exits(room),
        visible_contents(actor: actor, cont: room),
        visible_contents(actor: actor, cont: actor) ]
          .flatten
          .compact
          .select { |e| get_component(e, :closable) }
    end
  end
end
