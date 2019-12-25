context System::Connections do
  include World::Helpers

  before(:all) { load_test_world }
  let(:player) { create_entity(base: 'base:player') }
  let(:conn_comp ) { get_component!(player, ConnectionComponent) }
  let(:conn) do
    conn = instance_double("TelnetServer::Connection")
    allow(conn).to receive(:error?).and_return(false)
    allow(conn).to receive(:last_recv).and_return(Time.now)
    conn
  end

  def run_update
    System::Connections.update(player, conn_comp)
  end

  describe '.update(id, connection)' do
    context 'no connection' do
      it 'will not do anything' do
        expect { System::Connections.update(player, conn_comp) }
            .to_not raise_error
      end
    end

    context 'client has disconnected' do
      before(:each) do
        expect(conn).to receive(:error?).and_return(true)
        allow(conn).to receive(:close_connection)
        conn_comp.conn = conn
      end
      it 'will close the connection' do
        expect(conn_comp.conn).to receive(:close_connection)
        run_update
      end
      it 'will clear the conn field' do
        run_update
        expect(conn_comp.conn).to be(nil)
      end
    end

    context 'client is idle' do
      it 'will move player into the void'
    end

    context 'client has timed out' do
      before(:each) do
        expect(conn).to receive(:last_recv)
            .and_return(Time.now - System::Connections::DISCONNECT_TIMEOUT)
        allow(conn).to receive(:close_connection_after_writing)
        allow(conn).to receive(:send_data)
        conn_comp.conn = conn
      end
      it 'will notify the client of the timeout' do
        expect(conn_comp.conn).to receive(:send_data)
        run_update
      end
      it 'will close the connection after sending data' do
        expect(conn_comp.conn).to receive(:close_connection_after_writing)
        run_update
      end
      it 'will clear the conn field' do
        run_update
        expect(conn_comp.conn).to be(nil)
      end
    end

    context 'with no data queued for output' do
      it 'will not send data to the client' do
        expect(conn).to_not receive(:send_data)
        conn_comp = conn
        run_update
      end
    end

    context 'with data queued for output' do
      before(:each) do
        conn_comp.buf = 'passed'
        allow(conn).to receive(:send_data)
        conn_comp.conn = conn
      end
      it 'will send the data to the client' do
        expect(conn_comp.conn).to receive(:send_data).with('passed')
        run_update
      end
      it 'will clear the queued data' do
        run_update
        expect(conn_comp.buf).to be_empty
      end
    end
  end
end
