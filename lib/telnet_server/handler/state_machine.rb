module TelnetServer::Handler::StateMachine
  class Error < StandardError;end
  class StateAlreadyDefined < Error; end
  class UnknownState < Error; end
  class UnsupportedHandlerType < Error; end

  module ClassMethods
    attr_reader :states

    # Set the initial state for the StateMachine
    def initial_state(state)
      @initial_state = state
    end

    # Define a valid state for the StateMachine
    def state(name,p={},&block)
      raise StateAlreadyDefined, "state #{name} already defined" if
          @states.has_key?(name)
      @initial_state ||= name
      @states[name] = State.new(&block)
    end
  end

  def self.included(klass)
    klass.extend(ClassMethods)
    klass.instance_variable_set(:@states, {})
  end

  # Get the current state
  def state
    @state ||= self.class.instance_variable_get(:@initial_state)
  end

  # Change the state of the machine
  def state=(new)
    return if new == state
    raise UnknownState, "unknown state #{new}" unless
        self.class.states.has_key?(new)
    orig = state
    begin
      @state = new
      call_handler(:enter, orig)
    rescue Error
      @state = orig
      raise
    end
  end

  # handle a line of input
  def input_line(line)
    call_handler(:input, line)
    call_handler(:prompt)
  end

  # active handler is called when this input handler begins receiving input
  def active=(v)
    @active = !!v
    if active?
      call_handler(:enter)
      call_handler(:prompt)
    end  
  end

  def active?
    !!@active
  end

  private

  # Call a handler
  def call_handler(type,*args)
    return unless active?
    state = self.class.states[self.state] or
        raise UnknownState, "unknown state #{self.state}"
    handler = state.handler(type) or return
    instance_exec(*args, &handler)
  end

  def yes(line)
    line =~ /^y(e|es)?$/i
  end

  def no(line)
    line =~ /^no?$/i
  end

  def set_state(new, *args)
    self.state = new
    nil
  end
end

require_relative 'state_machine/state'
