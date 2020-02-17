# Connection handler for telnet connections.
class Morrow::TelnetServer::Connection < EventMachine::Connection
  include EventMachine::Protocols::LineProtocol

  attr_accessor :server, :color
  attr_reader :host, :port

  def post_init
    super
    @port, @host = Socket.unpack_sockaddr_in(get_peername)
    @handler = []
  end

  def unbind
    server.connections.delete(self)
  end

  def inspect
    '#<%s src=%s:%p>' % [ self.class.name, @host, @port ]
  end

  def receive_line(line)
    if reply = handler.input_line(line)
      send_data(reply)
    end
  end

  # push a new input handler onto the stack
  def push_handler(new_handler)
    new_handler = new_handler.new(self) if new_handler.is_a?(Class)
    @handler.push(new_handler)
    new_handler.resume
    nil
  end

  # pop the top-most input handler
  def pop_handler
    @handler.pop
    handler&.resume or close_connection_after_writing
    nil
  end

  def handler
    @handler.last
  end

  def handler=(h)
    @handler.clear
    push_handler(h)
  end

  def send_data(buf)
    return unless buf
    super apply_colors(buf.to_s)
  end

  COLOR_CODE_REGEX = Regexp.new(/&([0rgbcwypk&\.])/i)
  COLOR_MAP = {
    '&K' => '1;30',
    '&r' => '0;31', '&R' => '1;31',
    '&g' => '0;32', '&G' => '1;32',
    '&y' => '0;33', '&Y' => '1;33',
    '&b' => '0;34', '&B' => '1;34',
    '&m' => '0;35', '&M' => '1;35',
    '&c' => '0;36', '&C' => '1;36',
    '&w' => '0;37', '&W' => '1;37',
    '&0' => '0' }
  def apply_colors(buf)
    # encoding is forced here because gsub complains about telnet IAC (\xff)
    # when the encoding is UTF-8
    buf.force_encoding("ASCII-8BIT").gsub(COLOR_CODE_REGEX) do |code|
      code = COLOR_MAP.keys.sample if code == '&.'
      handler.color? ? "\e[%sm" % [ COLOR_MAP[code] ] : ''
    end
  end
end
