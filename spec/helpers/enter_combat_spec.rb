describe 'Morrow::Helpers.enter_combat' do
  let(:room) { 'spec:room/1' }
  let(:actor) { 'spec:char/actor' }
  let(:victim) { 'spec:char/victim' }

  before(:each) do
    reset_world
    move_entity(entity: actor, dest: room)
    move_entity(entity: victim, dest: room)
  end

  context 'target is actor' do
    it 'will raise InvalidEntity' do
      expect { enter_combat(actor: actor, target: actor) }
          .to raise_error(Morrow::InvalidEntity)
    end
  end
end
