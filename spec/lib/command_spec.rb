describe Command do
  include World::Helpers

  before(:all) { load_test_world }

  describe '.run' do
    let(:actor) { create_entity(base: 'base:player') }
    context 'when command contains regex characters' do
      it 'will not error' do
        expect { Command.run(actor, '[') }.to_not raise_error
      end
    end
  end
end
