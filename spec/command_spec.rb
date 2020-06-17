describe Morrow::Command do
  before(:all) { Morrow.reset!; Morrow.load_world }
  let(:leo) { 'spec:mob/leonidas' }
  let(:output) { player_output(leo) }

  context 'when extended into a module' do
    context 'when a public method is declared' do
      before(:each) do
        Module.new do
          extend Morrow::Command

          class << self

            # Help text for the test command
            def test(actor, args)
              send_to_char(char: actor, buf: 'passed')
            end
          end
        end
        output.clear
      end

      after(:each) { Morrow.config.commands.delete('test') }

      it 'will register a new command' do
        expect(cmd_output(leo, 'test')).to include('passed')
      end
    end

    context 'when a private method is declared' do
      before(:each) do
        Module.new do
          extend Morrow::Command

          class << self

            private

            def test(actor, args)
              raise 'ERROR! The command WAS registered!'
            end
          end
        end

        output.clear
      end

      after(:each) { Morrow.config.commands.delete('test') }

      it 'will not register a new command' do
        run_cmd(leo, 'test')
        expect(output).to include('unknown command')
      end
    end
  end

  describe 'standing!' do
    let(:actor) { spawn(base: 'spec:char/actor' ) }
    let(:command) do
      Module.new do
        extend Morrow::Command
      end
    end

    where(:position, :will_raise) do
      [ [ :standing,  false ],
        [ :sitting,   true  ],
        [ :lying,     true  ],
      ]
    end

    with_them do
      before do
        get_component(actor, :character).position = position
      end

      it 'will raise an error if actor is not standing' do
        if will_raise
          expect { command.standing!(actor) }
              .to raise_error(Morrow::Command::Error, /standing/)
        else
          expect { command.standing!(actor) }.to_not raise_error
        end
      end
    end
  end

  describe 'conscious!' do
    let(:actor) { spawn(base: 'spec:char/actor' ) }
    let(:command) do
      Module.new do
        extend Morrow::Command
      end
    end

    context' when actor is conscious' do
      before { get_component(actor, :character).unconscious = false }

      it 'will not raise an error' do
        expect { command.conscious!(actor) }.to_not raise_error
      end
    end

    context 'when actor is unconscious' do
      before { get_component(actor, :character).unconscious = true }
      it 'will raise a Command::Error' do
        expect { command.conscious!(actor) }
            .to raise_error(Morrow::Command::Error, /unconscious/i)
      end
    end
  end

  describe 'able!' do
    let(:actor) { spawn(base: 'spec:char/actor' ) }
    let(:command) do
      Module.new do
        extend Morrow::Command
      end
    end

    where(:health, :will_raise) do
      [ [  1, false ],
        [  0, true  ],
        [ -1, true  ],
      ]
    end

    with_them do
      before do
        get_component(actor, :character).health = health
      end

      it 'will raise an error if actor is incapacitated' do
        if will_raise
          expect { command.able!(actor) }
              .to raise_error(Morrow::Command::Error, /incapacitated/)
        else
          expect { command.able!(actor) }.to_not raise_error
        end
      end
    end
  end

  describe 'out_of_combat!' do
    let(:room) { 'spec:room/1' }
    let(:actor) { spawn_at(base: 'spec:char/actor', dest: room) }
    let(:victim) { spawn_at(base: 'spec:char/victim', dest: room) }
    let(:command) do
      Module.new do
        extend Morrow::Command
      end
    end

    context' when actor is not in combat' do
      it 'will not raise an error' do
        expect { command.out_of_combat!(actor) }.to_not raise_error
      end
    end

    context 'when actor is in combat' do
      before { enter_combat(actor: actor, target: victim) }

      it 'will raise a Command::Error' do
        expect { command.out_of_combat!(actor) }
            .to raise_error(Morrow::Command::Error, /in combat/i)
      end
    end
  end

  describe 'in_combat!' do
    let(:room) { 'spec:room/1' }
    let(:actor) { spawn_at(base: 'spec:char/actor', dest: room) }
    let(:victim) { spawn_at(base: 'spec:char/victim', dest: room) }
    let(:command) do
      Module.new do
        extend Morrow::Command
      end
    end

    context' when actor is not in combat' do
      it 'will raise a Command::Error' do
        expect { command.in_combat!(actor) }
            .to raise_error(Morrow::Command::Error, /in combat/i)
      end
    end

    context 'when actor is in combat' do
      before { enter_combat(actor: actor, target: victim) }

      it 'will not raise an error' do
        expect { command.in_combat!(actor) }.to_not raise_error
      end
    end
  end
end
