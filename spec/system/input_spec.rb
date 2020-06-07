describe Morrow::System::Input do
  before(:all) { reset_world }

  let(:leo) { 'spec:mob/leonidas' }
  let(:queue) { Thread::Queue.new }
  let(:input) { get_component!(leo, :input) }
  let(:output) { strip_color_codes(player_output(leo)) }

  before(:each) do
    input.queue = queue
    player_output(leo).clear
  end

  # Fake like we're Morrow.update.  Update the start time, then call the system
  # directly on the bag.
  def run_update
    Morrow.instance_eval { @update_start_time = Time.now }
    Morrow::System::Input.update(leo, input)
  end

  context 'when the queue is empty' do
    it 'will not run a command' do
      expect(Morrow::System::Input).to_not receive(:run_cmd)
      run_update
    end
  end

  context 'when the queue has a single command' do
    before(:each) { queue.push('passed') }

    it 'will run the command' do
      expect(Morrow::System::Input)
          .to receive(:run_cmd).with(leo, 'passed')
      run_update
    end

    it 'will remove the command from the queue' do
      run_update
      expect(queue.empty?).to be(true)
    end
  end

  context 'when the queue has multiple commands' do
    before(:each) { 10.times { queue.push('cmd') } }

    it 'will run only a single command' do
      expect(Morrow::System::Input).to receive(:run_cmd).once
      run_update
    end

    it 'will only remove the first command from the queue' do
      run_update
      expect(queue.size).to be(9)
    end
  end

  context 'when .run_cmd() raises an Exception' do
    before(:each) do
      toggle_logging
      allow(Morrow::System::Input)
          .to receive(:run_cmd).and_raise(RuntimeError)
      queue.push('cmd')
    end

    after(:each) { toggle_logging }

    it 'will log the exception' do
      before = Morrow.exceptions.last
      run_update
      expect(Morrow.exceptions.last).to_not eq(before)
    end

    it 'will display an error to the player' do
      run_update
      expect(output).to include('error in command')
    end
  end
end
