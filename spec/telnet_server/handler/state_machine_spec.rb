require 'telnet_server'

describe TelnetServer::Handler::StateMachine do

  def new_machine(&block)
    klass = Class.new
    klass.include(TelnetServer::Handler::StateMachine)
    klass.instance_eval(&block)
    klass.new
  end

  context 'configuration' do
    describe 'initial_state' do
      context 'when not set' do
        before(:all) do
          @machine = new_machine do
            state :first
            state :second
          end
        end
        it 'will use the first defined state as the initial state' do
          expect(@machine.state).to eq(:first)
        end
      end
      context 'when set' do
        before(:all) do
          @machine = new_machine do
            initial_state :initial
          end
        end
        it 'will start in the specified state' do
          expect(@machine.state).to eq(:initial)
        end
      end
    end

    describe 'state' do
      context 'state already exists' do
        it 'will raise an exception' do
          expect do
            new_machine do
              state :first
              state :first
            end
          end.to raise_error(TelnetServer::Handler::StateMachine::StateAlreadyDefined)
        end
      end

      context 'state is not already defined' do
        it 'will add a new state' do
          machine = new_machine do
            state :first
          end
          expect(machine.class.states).to have_key(:first)
        end
        it 'will create a new State instance' do
          machine = new_machine do
            state :first
          end
          expect(machine.class.states[:first])
              .to be_a(TelnetServer::Handler::StateMachine::State)
        end
        it 'will evaluate the block within the State instance' do
          example = self
          machine = new_machine do
            state(:first) do
              example.instance_variable_set(:@binding, binding)
            end
          end
          expect(@binding.receiver).to be(machine.class.states[:first])
        end
      end
    end
  end

  context 'execution' do
    describe '#input_line' do
      context 'state is valid' do
        before(:all) do
          @machine = new_machine do
            attr_reader :line, :prompt_called, :input_binding
            state(:state) do
              input do |line|
                @input_binding = binding
                @line = line
              end
              prompt { @prompt_called = true }
            end
          end
          @machine.active = true
          @machine.input_line('test123')
        end

        it 'will call input handler in the scope of the StateMachine instance' do
          expect(@machine.input_binding.receiver).to be(@machine)
        end
        it 'will call the handler with the line provided' do
          expect(@machine.line).to eq('test123')
        end
        it 'will call the prompt handler' do
          expect(@machine.prompt_called).to eq(true)
        end
      end

      context 'state is invalid' do
        it 'will raise UnknownState' do
          @machine = new_machine do
            initial_state :invalid
          end
          expect(@machine).to receive(:active?).and_return(true)

          expect { @machine.input_line('test123') }.to \
              raise_error(TelnetServer::Handler::StateMachine::UnknownState)
        end
      end
    end

    describe '#state=' do
      context 'state is invalid' do
        it 'will raise UnknownState' do
          machine = new_machine {}
          expect { machine.state = :bad_state }.to \
              raise_error(TelnetServer::Handler::StateMachine::UnknownState)
        end
      end

      context 'new state is the same as current state' do
        it 'will not execute in handler for state' do
          machine = new_machine do
            attr_reader :called
            state :first, in: proc { @called = true }
          end
          machine.state = :first
          expect(machine.called).to eq(nil)
        end
      end

      context 'state is valid and different' do
        it 'will change the state' do
          machine = new_machine do
            state :first
            state :second
          end
          machine.state = :second
          expect(machine.state).to eq(:second)
        end

        it 'will execute enter handler defined for the new state' do
          machine = new_machine do
            attr_reader :called
            state :first
            state(:second) { enter { @called = true } }
          end
          expect(machine).to receive(:active?).and_return(true)
          machine.state = :second
          expect(machine.called).to eq(true)
        end
      end
    end
  end
end
