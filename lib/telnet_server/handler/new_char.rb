require_relative '../../password_storage.rb'

class TelnetServer::Handler::NewChar < TelnetServer::Handler::Base
  include TelnetServer::Handler::StateMachine
  extend Forwardable

  def initialize(conn, name)
    super(conn)
    @world = conn.world
    @char = World::Pc.new
    @char.name = name
  end

  state(:verify_name) do
    prompt do 
      send_data "Create new character, #{@char.name} (Y/N)? "
    end

    input do |line|
      if yes(line)
        set_state :enter_password
      elsif no(line)
        conn.pop_input_handler
      else
        send_line "Invalid response."
      end
    end
  end

  state(:enter_password) do
    prompt("Enter your password: ")
    input do |line|
      @password = line
      set_state :verify_password
    end
  end

  state(:verify_password) do
    prompt("Re-enter password: ")
    input do |line|
      if line == @password
        @char.password = PasswordStorage.createHash(@password)
        @password = nil
        set_state :select_race
      else
        send_line("Passwords mis-match")
        set_state :enter_password
      end
    end
  end

  state(:select_race) do
    selection(prompt: 'Choose a race',
        choices: proc { World::Race.select { |r| r.playable? } },
        display: proc { |r| "%-10s  %s" % [r.name, r.desc] },
        help: proc { send_line "help pending" }) do |choice|
      @race = choice
      set_state :confirm_race
    end
  end

  state(:confirm_race) do
    prompt { "Are you sure you wish to be a #{@race.name}? " }
    input do |line|
      if yes(line)
        @char.race = @race
        set_state :select_class
      elsif no(line)
        set_state :select_race
      else
        'Invalid response\n'
      end
    end
  end

  state(:select_class) do
    selection(prompt: 'Choose a class',
        choices: proc { @char.race.classes },
        display: proc { |r| "%-10s  %s" % [r.name, r.desc] },
        help: proc { send_line "help pending" }) do |choice|
      @class = choice
      set_state :confirm_class
    end
  end

  state(:confirm_class) do
    prompt { "Are you sure you wish to be a #{@class.name}? " }
    input do |line|
      if yes(line)
        @char.levels[@class] = 1
        conn.set_handler(TelnetServer::Handler::Player.new(conn, @char, @world))
      elsif no(line)
        set_state :select_race
      else
        'Invalid response\n'
      end
    end
  end

end
