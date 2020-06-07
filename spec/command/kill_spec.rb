describe 'Morrow::Helpers.damage_entity' do
  let(:room) { 'spec:room/1' }
  let(:actor) { 'spec:char/actor' }
  let(:victim) { 'spec:char/victim' }

  before(:each) do
    reset_world
    move_entity(entity: actor, dest: room)
    move_entity(entity: victim, dest: room)
  end

  context 'target is absent' do
    before(:each) { move_entity(entity: victim, dest: 'spec:room/2') }

    it 'will output "You do not see them here."' do
      expect(cmd_output(actor, 'kill victim'))
          .to include('You do not see them here.')
    end
  end

  context 'target is present' do
    it 'will call hit_entity()' do
      expect(Morrow::Command::Kill)
          .to receive(:hit_entity).with(actor: actor, entity: victim)
      run_cmd(actor, 'kill victim')
    end
  end

  context 'target is actor' do
    it 'will output "You take a swing at yourself and miss."' do
      expect(cmd_output(actor, 'kill actor'))
          .to include('You take a swing at yourself and miss.')
    end
  end
end
