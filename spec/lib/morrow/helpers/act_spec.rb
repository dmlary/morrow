describe 'Morrow::Helpers.act' do
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
    { fmt: '%{actor} %{v:be} incapacitated, and may not recover.',
      actor: 'You are incapacitated, and may not recover.',
      victim: 'Actor is incapacitated, and may not recover.',
      observer: 'Actor is incapacitated, and may not recover.' },
    { fmt: '%{victim} %{v:dodge} %{poss:actor} attack!',
      actor: 'Victim dodges your attack!',
      victim: 'You dodge Actor\'s attack!',
      observer: 'Victim dodges Actor\'s attack!' },
    { fmt: '%{actor} %{v:swing} at %{victim},' +
        ' but %{p:victim} dodge the blow.',
      actor: 'You swing at Victim, but they dodge the blow.',
      victim: 'Actor swings at you, but you dodge the blow.',
      observer: 'Actor swings at Victim, but they dodge the blow.' },
  ].each do |p|
    describe p[:fmt].inspect do
      before(:each) { act(p[:fmt], actor: actor, victim: victim) }

      %i{ actor victim observer }.each do |entity|
        next unless p[entity]
        it "will output '#{p[entity]}' to #{entity}" do
          expect(output(send(entity))).to include(p[entity])
        end
      end
    end
  end
end
