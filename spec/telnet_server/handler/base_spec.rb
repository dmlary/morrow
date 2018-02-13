require 'telnet_server'

describe TelnetServer::Handler::Base do
  let (:conn) { double('Connection') }
  let (:base) { TelnetServer::Handler::Base.new(conn) }

  describe '#send_line' do
    it 'will call #send_data on conn' do
      expect(conn).to receive(:send_data)
      base.send_line('test')
    end
    it 'will append a newline to argument' do
      expect(conn).to receive(:send_data).with("test\n")
      base.send_line('test')
    end
  end
end
