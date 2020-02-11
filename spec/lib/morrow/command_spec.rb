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
        run_cmd(leo, 'test')
        expect(output).to eq('passed')
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
end
