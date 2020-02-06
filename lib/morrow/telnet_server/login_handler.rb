class Morrow::TelnetServer::LoginHandler
  include Morrow::TelnetServer::InputHandler

  def input_line(line)
    send_line("recv: #{line}")
  end
end
