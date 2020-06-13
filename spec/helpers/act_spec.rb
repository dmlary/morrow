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
    player_output(entity)
  end

  [ { fmt: '%{actor} %{v:smile} at %{victim}.',
      to_actor: 'You smile at Victim.',
      to_victim: 'Actor smiles at you.',
      to_observer: 'Actor smiles at Victim.' },
    { fmt: '%{actor} %{v:be} incapacitated, and may not recover.',
      to_actor: 'You are incapacitated, and may not recover.',
      to_victim: 'Actor is incapacitated, and may not recover.',
      to_observer: 'Actor is incapacitated, and may not recover.' },
    { fmt: '%{victim} %{v:dodge} %{poss:actor} attack!',
      to_actor: 'Victim dodges your attack!',
      to_victim: 'You dodge Actor\'s attack!',
      to_observer: 'Victim dodges Actor\'s attack!' },
    { fmt: '%{actor} %{v:swing} at %{victim},' +
        ' but %{p:victim} dodge the blow.',
      to_actor: 'You swing at Victim, but they dodge the blow.',
      to_victim: 'Actor swings at you, but you dodge the blow.',
      to_observer: 'Actor swings at Victim, but they dodge the blow.' },
    { fmt: '%{actor} %{v:flee} to the %{dir}!',
      args: { in: 'spec:room/1', dir: 'north' },
      actor_room: 'spec:room/2',
      to_actor: false,
      to_victim: 'Actor flees to the north!',
      to_observer: 'Actor flees to the north!' },
    { fmt: '&Ract will skip color codes for capitalization!&0',
      to_actor: '&RAct will skip color codes for capitalization!&0' },
  ].each do |p|
    describe p[:fmt].inspect do
      before(:each) do
        move_entity(entity: actor, dest: p[:actor_room]) if p[:actor_room]

        args = { actor: actor, victim: victim }
        args.merge!(p[:args]) if p[:args]
        act(p[:fmt], **args)
      end

      %i{ actor victim observer }.each do |entity|
        key = ('to_%s' % entity).to_sym
        msg = p[key]
        next if msg.nil?

        if msg
          it "will output '#{msg}' to #{entity}" do
            expect(output(send(entity))).to include(msg)
          end
        else
          it "will not write output to #{entity}" do
            expect(output(send(entity))).to be_empty
          end
        end
      end
    end
  end
end
