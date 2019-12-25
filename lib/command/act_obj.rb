module Command::ActObj
  extend World::Helpers

  class << self
    def open_entity(actor, arg=nil)
      return "Open what?\n" if arg.nil? || arg.empty?

      target = match_keyword(arg, closable_entities(actor)) or
          return "Unable to find anything named '#{arg}' to open."

      comp = get_component(target, ClosableComponent)
      return "It is locked." if comp.locked
      return "It is already open." if !comp.closed

      comp.closed = false

      # XXX need to do the same to the door on the other side; both should be
      # closable
      return "You open #{entity_short(target)}"
    end

    def close_entity(actor, arg=nil)
      return "Close what?\n" if arg.nil? || arg.empty?

      target = match_keyword(arg, closable_entities(actor)) or
          return "Unable to find anything named '#{arg}' to close."

      comp = get_component(target, ClosableComponent)
      return "It is already closed." if comp.closed

      comp.closed = true
      return "You close #{entity_short(target)}"
    end

    def closable_entities(actor)
      room = entity_location(actor)  or fault "actor has no location", actor
      [ visible_exits(actor: actor, room: room),
        visible_contents(actor: actor, cont: room),
        visible_contents(actor: actor, cont: actor) ]
          .flatten
          .compact
          .select { |e| get_component(e, ClosableComponent) }
    end
  end

  # Register the commands
  Command.register('open', method: method(:open_entity))
  Command.register('close', method: method(:close_entity))
end
