module Command::Movement
  extend World::Helpers

  World::CARDINAL_DIRECTIONS.each do |dir|
    Command.register(dir) do |actor|
      traverse_passage(actor, dir)
    end
  end

  class << self
    def traverse_passage(actor, name)
      current = actor.get(:location) or fault "no current location", actor

      passage = current.get(:exits).map(&:resolve).find do |pass|
        pass.get(:keywords).include?(name)
      end

      if passage.nil?
        "Alas, you cannot go that way...\n"
      elsif passage.get(:closable, :closed)
        "The path #{name} seems to be closed.\n"
      else
        dest = passage.get(:destination)
        move_entity(actor, dest)
        Command::Look.show_room(actor, dest)
      end
    end
  end
end
