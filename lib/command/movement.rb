module Command::Movement
  extend World::Helpers

  World::CARDINAL_DIRECTIONS.each do |dir|
    Command.register(dir, priority: 1000) do |actor|
      traverse_passage(actor, dir)
    end
  end

  class << self
    def traverse_passage(actor, name)
      current = actor.get(:location, :ref) or
          fault "no current location", actor

      passage = current.entity
          .get(:exits, :list)
          .map(&:entity)
          .find do |pass|
            pass.get(:keywords, :words).include?(name)
          end

      if passage.nil?
        "Alas, you cannot go that way...\n"
      elsif passage.get(:closable, :closed)
        "The path #{name} seems to be closed.\n"
      else
        dest = passage.get(:destination, :ref).entity
        move_entity(actor, dest)
        Command::Look.show_room(actor, dest)
      end
    end
  end
end
