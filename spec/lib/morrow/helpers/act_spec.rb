describe 'Morrow::Helpers::Scriptable#act' do
  let(:room) { 'spec:room/1' }
  let(:actor) { 'spec:char/actor' }
  let(:victim) { 'spec:char/victim' }
  let(:observer) { 'spec:char/observer' }

  before(:all) do
    reset_world
    @parties = %i{ actor victim observer }
    @parties.each do |type|
      move_entity(entity: "spec:char/#{type}", dest: 'spec:room/1')
    end
  end

  before(:each) do
    [ actor, victim, observer ].each { |e| player_output(e).clear }
  end

  def output(entity)
    strip_color_codes(player_output(entity))
  end

  [ { fmt: '%{actor} %{v:smile} at %{victim}.',
      actor: 'You smile at Victim.',
      victim: 'Actor smiles at you.',
      observer: 'Actor smiles at Victim.' },
  ].each do |p|
    describe p[:fmt].inspect do
      before(:each) { act(p[:fmt], actor: actor, victim: victim) }

      %i{ actor victim observer }.each do |entity|
        next unless p[entity]
        it "will output '#{p[entity]}' to #{entity}" do
          expect(output(send(entity))).to eq(p[entity])
        end
      end
    end
  end
end
