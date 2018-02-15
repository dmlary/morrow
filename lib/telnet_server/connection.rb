class TelnetServer::Connection < EventMachine::Connection
  include EventMachine::Protocols::LineProtocol
  extend Forwardable

  attr_accessor :server
  attr_reader :handler, :host, :port, :last_recv

  def post_init
    super
    @authenticated = false
    @handler = []
    @port, @host = Socket.unpack_sockaddr_in(get_peername)
    @last_recv = Time.now
  end

  def inspect
    '#<%s src=%s:%p>' % [ self.class.name, @host, @port ]
  end

  def char
    active_handler.char
  end

  def unbind
    server.connections.delete(self)
  end

  def receive_line(line)
    # XXX snoop
    # XXX exception catching/handling/storing
    @last_recv = Time.now
    send_data @handler.last.input_line(line)
  end

  # push a new input handler onto the stack
  def push_input_handler(handler)
    active_handler.active = false unless @handler.empty?
    @handler.push(handler)
    handler.active = true
  end

  # pop the top-most input handler
  def pop_input_handler
    old = @handler.pop
    old.active = false if old

    if @handler.empty?
      close_connection_after_writing
    else
      active_handler.active = true
    end
    nil
  end

  # clear all handlers, and put a new handler as the sole handler
  def set_handler(h)
    if old = active_handler
      old.active = false
    end
    @handler.clear
    @handler.push(h)
    h.active = true
  end

  def active_handler
    @handler.last
  end

  def world
    World
  end
end
