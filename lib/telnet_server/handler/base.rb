require 'forwardable'

class TelnetServer::Handler::Base
  extend Forwardable

  attr_reader :conn
  def initialize(conn)
    @conn = conn
  end
 
  def send_data(buf)
    @conn.send_data(buf)
    nil
  end

  def send_line(line)
    send_data(line + "\n")
    nil
  end

  def active=(v)
    @active = !!v
  end

  def active?
    @active == true
  end
end
