class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  include World::Helpers

  def initialize(conn)
    # What is the difference between a tag and a class/module/constant?

    # Create a new entity in the world
    @char = World.new_entity('base:player')
    @cmd_queue = Queue.new
    @char.set(:connection, conn)
    @char.set(:command_queue, @cmd_queue)
    @char.set(:player_config, :color, true)

    # Add this char to the world
    World.add_entity(@char)

    # move the player into the void
    void = World.by_virtual('base:room/void')
    move_entity(@char, void)

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
