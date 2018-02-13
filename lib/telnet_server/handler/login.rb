class TelnetServer::Handler::Login < TelnetServer::Handler::Base
  include TelnetServer::Handler::StateMachine

  # Entry screen
  state(:login) do
    enter do
      begin
        send_line "\nGeneric Ruby Mud\n\n" unless @seen_banner
      ensure
        @seen_banner = true
      end
    end

    prompt("By what name do you wish to be known? ")

    input do |name|
      name.capitalize!
      if @char = conn.world.pc(name)
        state = :authenticate
      else
        handler = TelnetServer::Handler::NewChar.new(conn, name)
        conn.push_input_handler(handler)
        nil
      end
    end
  end

  state(:authenticate) do
    prompt("Password: ")
    input do |password|
      if @char.authenticate?(password)
        conn.pop_input_handler
        handler = TelnetServer::Handler::Connected.new(conn, name)
        conn.push_input_handler(handler)
      else
        send_line("Bad password")
        state = :login
      end
    end
  end
end
