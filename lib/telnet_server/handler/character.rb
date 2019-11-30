class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  include World::Helpers

  def initialize(conn)
    # What is the difference between a tag and a class/module/constant?

    # Create a new entity in the world
    @char = Entity.new(:player_char)
    @cmd_queue = Queue.new
    @char.set(:connection, conn)
    @char.set(:command_queue, @cmd_queue)
    @char.set(:player_config, :color, true)

    # Add this char to the world
    World.add_entity(@char)

    # Set the character's location (first room we can find
    limbo = World.by_virtual('limbo/room/limbo')
    move_entity(@char, limbo)

    # Add the 'look' command to the queue
    @cmd_queue.push('look')
  end

  def input_line(line)
    @cmd_queue.push(line)
    nil
  end

  def color?
    @char.get(:player_config, :color)
  end
end
