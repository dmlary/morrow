describe Morrow::Command::CharPosition do
  let(:actor)     { spawn(base: 'spec:char/actor') }
  let(:observer)  { spawn(base: 'spec:char/observer') }
  let(:room)      { 'spec:room/1' }
  let(:output)    { strip_color_codes(player_output(actor)) }
  let(:char)      { get_component(actor, :character) }

  before do
    reset_world
    move_entity(entity: actor, dest: room)
    player_output(actor).clear
    move_entity(entity: observer, dest: room)
    player_output(observer).clear
  end

  def set_char_position(pos)
    case pos
    when :standing
      char.position = :standing
      char.unconscious = false
    when :sitting
      char.position = :sitting
      char.unconscious = false
    when :resting
      char.position = :lying
      char.unconscious = false
    when :sleeping
      char.position = :lying
      char.unconscious = true 
    else
      raise "unknown pos: #{pos}"
    end
  end

  where(:start_pos, :cmd, :pos, :unconscious, :update, :to_actor, :to_room) do
    [ [ :standing, 'stand', :standing, false, false,
          'You are already standing.', nil ],
      [ :sitting,  'stand', :standing, false, true,
          'You stand up.', 'Actor stands up.'],
      [ :resting,  'stand', :standing, false, true,
          'You stand up.', 'Actor stands up.'],
      [ :sleeping, 'stand', :standing, false, true,
          'You stand up.', 'Actor stands up.'],

      [ :standing, 'sit', :sitting, false, true,
          'You sit down.', 'Actor sits down.'],
      [ :sitting,  'sit', :sitting, false, false,
          'You are already sitting.', nil ],
      [ :resting,  'sit', :sitting, false, true,
          'You sit up.', 'Actor sits up.'],
      [ :sleeping, 'sit', :sitting, false, true,
          'You sit up.', 'Actor sits up.'],

      [ :standing, 'rest', :lying, false, true,
          'You lay down.', 'Actor lays down.'],
      [ :sitting,  'rest', :lying, false, true,
          'You lay down.', 'Actor lays down.'],
      [ :resting,  'rest', :lying, false, false,
          'You are already resting.', nil ],
      [ :sleeping, 'rest', :lying, false, true,
          'You wake up.', 'Actor wakes up.'],

      [ :standing, 'sleep', :lying, true, true,
          'You lay down and fall asleep.', 'Actor lays down and falls asleep.'],
      [ :sitting,  'sleep', :lying, true, true,
          'You lay down and fall asleep.', 'Actor lays down and falls asleep.'],
      [ :resting,  'sleep', :lying, true, true,
          'You fall asleep.', 'Actor falls asleep.'],
      [ :sleeping, 'sleep', :lying, true, false,
          'You are already asleep.', nil ],

      [ :standing, 'wake', :standing, false, false,
          'You are already awake.', nil ],
      [ :sitting,  'wake', :sitting,  false, false,
          'You are already awake.', nil ],
      [ :resting,  'wake', :lying,    false, false,
          'You are already awake.', nil ],
      [ :sleeping, 'wake', :lying,    false, true,
          'You wake up.', 'Actor wakes up.'],
    ]
  end

  with_them do
    before { set_char_position(start_pos) }

    it 'will set the actor position' do
      run_cmd(actor, cmd)
      expect(char.position).to eq(pos)
    end

    it 'will set the actor unconscious field' do
      run_cmd(actor, cmd)
      expect(char.unconscious).to eq(unconscious)
    end

    it 'will send the expected output to the actor' do
      run_cmd(actor, cmd)
      expect(stripped_output(actor)).to include(to_actor)
    end

    it 'will send any expected output to the room' do
      run_cmd(actor, cmd)
      if to_room
        expect(stripped_output(observer)).to include(to_room)
      else
        expect(stripped_output(observer)).to be_empty
      end
    end

    it 'calls update_char_regen appropriately' do
      if update
        expect(described_class).to receive(:update_char_regen).with(actor)
      else
        expect(described_class).to_not receive(:update_char_regen)
      end
      run_cmd(actor, cmd)
    end
  end

  describe 'wake <char>' do
    let(:victim)    { spawn(base: 'spec:char/victim') }
    let(:char) { get_component(victim, :character) }

    context 'char is incapacitated' do
      before do
        move_entity(entity: victim, dest: room)
        damage_entity(entity: victim, actor: actor, amount: char.health)
        player_output(victim).clear
        run_cmd(actor, 'wake victim')
      end

      it 'will leave victim unconscious' do
        expect(char.unconscious).to eq(true)
      end

      it 'will send error to the actor' do
        expect(stripped_output(actor)).to include(<<~MSG)
          You try to wake Victim, but they are too hurt!
        MSG
      end

      it 'will nothing send to the victim' do
        expect(stripped_output(victim)).to be_empty
      end

      it 'will send a message to the room' do
        expect(stripped_output(observer)).to include(<<~MSG)
          Actor tries to wake Victim, but they are too hurt!
        MSG
      end

    end

    context 'char is not incapacitated' do
      before do
        move_entity(entity: victim, dest: room)
        run_cmd(victim, 'sleep')
        player_output(victim).clear
      end

      it 'will mark victim as conscious' do
        run_cmd(actor, 'wake victim')
        expect(char.unconscious).to eq(false)
      end

      it 'will call update_char_regen()' do
        expect(described_class).to receive(:update_char_regen).with(victim)
        run_cmd(actor, 'wake victim')
      end

      it 'will send to the actor, "You wake Victim!"' do
        run_cmd(actor, 'wake victim')
        expect(stripped_output(actor)).to include(<<~MSG)
          You wake Victim.
        MSG
      end

      it 'will send "Actor wakes you." to the victim' do
        run_cmd(actor, 'wake victim')
        expect(stripped_output(victim)).to include(<<~MSG)
          Actor wakes you.
        MSG
      end

      it 'will send a message to the room' do
        run_cmd(actor, 'wake victim')
        expect(stripped_output(observer)).to include(<<~MSG)
          Actor wakes Victim.
        MSG
      end
    end
  end
end
