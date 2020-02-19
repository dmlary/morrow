module Morrow::Command::ActClosable
  extend Morrow::Command

  class << self
    # Open something in the world
    #
    # Syntax: open <door>, open <container>
    #
    def open(actor, arg)
      command_error 'What would you like to open?' unless arg

      target = match_keyword(arg, closable_entities(actor)) or
          command_error 'You do not see that here.'

      comp = get_component(target, :closable)
      command_error 'It is locked.' if comp.locked
      command_error 'It is already open.' if !comp.closed

      comp.closed = false
      send_to_char(char: actor, buf: 'You open %s.' % entity_short(target))
    end

    # close something in the world
    #
    # Syntax: close <door>, close <container>
    #
    def close(actor, arg)
      command_error 'What would you like to close?' unless arg

      target = match_keyword(arg, closable_entities(actor)) or
          command_error 'You do not see that here.'

      comp = get_component(target, :closable)
      command_error 'It is already closed.' if comp.closed

      comp.closed = true
      send_to_char(char: actor, buf: 'You close %s.' % entity_short(target))
    end

    private

    def closable_entities(actor)
      room = entity_location(actor)  or fault "actor has no location", actor
      [ entity_doors(room),
        visible_contents(actor: actor, cont: room),
        visible_contents(actor: actor, cont: actor) ]
          .flatten
          .compact
          .select { |e| get_component(e, :closable) }
    end
  end
end
