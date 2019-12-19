class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  include World::Helpers

  def initialize(conn)
    # create our command queue
    @cmd_queue = Queue.new

    # Create a new player in the world (stick them in the void)
    void = World.by_virtual('base:room/void')
    @char = World.spawn(void, 'base:player')
    @char.set(:connection, conn: conn)
    @char.set(:command_queue, queue: @cmd_queue)
    @char.set(:player_config, color: true)

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
