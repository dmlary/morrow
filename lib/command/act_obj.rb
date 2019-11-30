module Command::ActObj
  extend World::Helpers

  class << self
    def open_entity(actor, arg=nil)
      return "Open what?\n" if arg.nil? || arg.empty?

      room = actor.get(:location)
      pool = room.get(:exits).map(&:resolve)
          .select { |e| e.has_component?(:closable) }

      target = match_keyword(arg, closable_entities(actor)) or
          return "Unable to find anything named '#{arg}' to open."
      
      return "It is locked." if target.get(:closable, :locked)
      return "It is already open." if !target.get(:closable, :closed)

      target.set(:closable, :closed, false)
      return "You open #{target.get(:viewable, :short)}"
    end

    def close_entity(actor, arg=nil)
      return "Close what?\n" if arg.nil? || arg.empty?

      target = match_keyword(arg, closable_entities(actor)) or
          return "Unable to find anything named '#{arg}' to close."
      
      return "It is already closed." if target.get(:closable, :closed)

      target.set(:closable, :closed, true)
      return "You close #{target.get(:viewable, :short)}"
    end

    def closable_entities(actor)
      room = actor.get(:location) or fault "actor has no location", actor
      [ room.get(:exits), actor.get(:container, :contents),
        room.get(:container, :contents) ]
          .flatten
          .compact
          .map(&:resolve)
          .select { |e| e.has_component?(:closable) }
    end
  end
  Command.register('open', method(:open_entity))
  Command.register('close', method(:close_entity))
end
