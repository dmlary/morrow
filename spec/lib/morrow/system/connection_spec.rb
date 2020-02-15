describe Morrow::System::Connection do
  before(:all) { reset_world }

  let(:leo) { 'spec:mob/leonidas' }
  let(:conn) { comp.conn }
  let(:comp) { get_component!(leo, :connection) }
  let(:output) { '' }

  before(:each) do
    comp.last_recv = Time.now
    comp.conn = instance_double('Morrow::TelnetServer::Connection')
    allow(comp.conn).to receive(:error?).and_return(false)
    allow(comp.conn).to receive(:close_connection)
    allow(comp.conn).to receive(:close_connection_after_writing)

    @output = ''
    allow(comp.conn).to receive(:send_data) { |b| @output << b }

    player_output(leo).clear
  end

  # Fake like we're Morrow.update.  Update the start time, then call the system
  # directly on the bag.
  def run_update
    Morrow.instance_eval { @update_start_time = Time.now }
    Morrow::System::Connection.update(leo, comp)
  end

  context 'when the server connection has an error' do
    before(:each) do
      allow(conn).to receive(:error?).and_return(true)
    end

    it 'will call #close_connection' do
      expect(conn).to receive(:close_connection)
      run_update
    end

    it 'will remove connection component' do
      run_update
      expect(entity_has_component?(leo, :connection)).to be(false)
    end
  end

  context 'when the connection has been idle for 15 minutes' do
    before(:each) do
      comp.last_recv = now - Morrow.config.disconnect_timeout
    end

    it 'will send any pending output' do
      comp.buf << 'passed'
      run_update
      expect(@output).to start_with('passed')
    end

    it 'will send a timeout message' do
      run_update
      expect(@output).to include('timed out')
    end

    it 'will close the connection' do
      expect(conn).to receive(:close_connection_after_writing)
      run_update
    end

    it 'will remove the connection component' do
      run_update
      expect(entity_has_component?(leo, :connection)).to be(false)
    end
  end

  context 'when the connection is active' do
    context 'when there is pending output' do
      before(:each) { comp.buf << 'passed' }

      it 'will send the pending output' do
        run_update
        expect(@output).to start_with('passed')
      end

      it 'will clear the pending output' do
        buf = comp.buf
        run_update
        expect(buf).to be_empty
      end

      it 'will send the prompt' do
        run_update
        expect(@output).to end_with(player_prompt(leo))
      end

      it 'will not close the session' do
        expect(conn).to_not receive(:close_connection_after_writing)
        expect(conn).to_not receive(:close_connection)
        run_update
      end

      it 'will not remove the connection component' do
        run_update
        expect(entity_has_component?(leo, :connection)).to be(true)
      end
    end

    context 'when there is no pending output' do
      before(:each) { comp.buf.clear }

      it 'will not send any data' do
        expect(conn).to_not receive(:send_data)
        run_update
      end

      it 'will not close the session' do
        expect(conn).to_not receive(:close_connection_after_writing)
        expect(conn).to_not receive(:close_connection)
        run_update
      end

      it 'will not remove the connection component' do
        run_update
        expect(entity_has_component?(leo, :connection)).to be(true)
      end
    end
  end
end
