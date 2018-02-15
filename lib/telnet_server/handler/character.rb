class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  def initialize(conn)
    # What is the difference between a tag and a class/module/constant?

    # Create a new entity in the world
    @char = Entity.new(:player)
    @char.get(:connection).value = conn
    @char.get(:command_queue).value = @cmd_queue = Queue.new

    # Set the character's location (first room we can find
    room = World.by_type(:room).first
    @char.get(:location).value = room.id

    # Add this char to the world
    World.add_entity(@char)

    # Add the 'look' command to the queue
    @cmd_queue.push('look')
  end

  def input_line(line)
    @cmd_queue.push(line)
    nil
  end
end
