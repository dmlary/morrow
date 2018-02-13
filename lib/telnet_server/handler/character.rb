class TelnetServer::Handler::Character < TelnetServer::Handler::Base
  def initialize(conn)
    # What is the difference between a tag and a class/module/constant?

    # Create a new entity in the world
    @char = World.new_entity(:char)

    # stick it in the first room we can find
    @char << World::Location.new(World.entities(:room).first)

    # Add the connection to the character
    @char << conn

    # set up a command queue, and add the look comman
    @char << @cmd_queue = CommandQueue.new
    @cmd_queue.push 'look'
  end
end
