context System::CommandQueue do
  include World::Helpers

  before(:all) { load_test_world }
  let(:player) { create_entity(base: 'base:player') }
  let(:queue_comp ) { get_component!(player, CommandQueueComponent) }
  let(:queue) { queue_comp.queue = Queue.new }

  def run_update
    System::CommandQueue.update(player, queue_comp)
  end

  describe '.update(id, queue_comp)' do
    context 'no queue' do
      it 'will not error' do
        queue_comp = nil
        expect { run_update }.to_not raise_error
      end
    end

    context 'empty queue' do
      it 'will not call Command.run' do
        expect(Command).to_not receive(:run)
        run_update
      end
    end

    context 'non-empty queue' do
      before(:each) do
        allow(Command).to receive(:run).and_return(nil)
      end
      it 'will pop the first element off the queue' do
        queue.push(:failed)
        run_update
        expect(queue).to be_empty
      end
      it 'will call Command.run with first element in queue' do
        queue.push('passed')
        expect(Command).to receive(:run).with(player, 'passed')
        run_update
      end
      it 'will not run multiple commands' do
        queue.push(:first)
        queue.push(:second)
        run_update
        expect(queue.size).to eq(1)
      end
    end

    context 'Command.run returns nil' do
      it 'will not call send_to_char' do
        expect(Command).to receive(:run).and_return(nil)
        expect(described_class).to_not receive(:send_to_char)
        queue.push('cmd')
        run_update
      end
    end

    context 'Command.run returns String' do
      it 'will call send_to_char' do
        expect(Command).to receive(:run).and_return('passed')
        expect(described_class).to receive(:send_to_char)
            .with(char: player, buf: 'passed')
        queue.push('cmd')
        run_update
      end
    end

    context 'Command.run raises an Exception' do
      it 'will save the exception'
      it 'will log an error'
      it 'will notify the player that an error occurred'
    end
  end
end
