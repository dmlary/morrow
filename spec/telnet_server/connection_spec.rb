require 'telnet_server'

describe TelnetServer::Connection do
  let(:conn) do
    c = TelnetServer::Connection.new
    c.post_init
  end

  describe '#receive_line' do
    let(:handler) do
      h = double()
      conn.push_input_handler(h)
      h
    end

    it 'will call #input_line on the top-most input handler' do
      pending "figuring out how to create Connection instance"
      expect(handler).to receive(:input_line)
      conn.receive_line('test123')
    end
  end
  describe '#push_input_handler' do
    it 'will push a new input handler on the handlers stack'
    context 'handler has #active method' do
      it 'will call the #active method'
    end
    context 'handler does not have #active method' do
      it 'will not try to call #active on the handler'
    end
  end

  describe '#pop_input_handler' do
    it 'will pop the top-most input handler off the stack'
  end
end
