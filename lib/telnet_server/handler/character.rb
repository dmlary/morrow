class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  include World::Helpers

  def initialize(conn)
    # What is the difference between a tag and a class/module/constant?

    # Create a new entity in the world
    @char = Entity.new(:player)
    @cmd_queue = Queue.new
    @char.set(:connection, conn)
    @char.set(:command_queue, @cmd_queue)

    # copy the color setting out of the player, into the connection
    conn.color = !!@char.get(:config_options, :color)

    # Add this char to the world
    World.add_entity(@char)

    # Set the character's location (first room we can find
    room = World.by_type(:room).first
    move_to_location(@char, room)

    # Add the 'look' command to the queue
    @cmd_queue.push('look')
  end

  def input_line(line)
    @cmd_queue.push(line)
    nil
  end
end
