class TelnetServer::Handler::StateMachine::State
  def initialize(&block)
    @handler = {}
    instance_exec(self, &block) if block
  end

  def handler(name)
    @handler[name]
  end

  private

  def set_handler(name, block)
    @handler[name] = block
  end

  def enter(string=nil,&block)
    block ||= proc { send_line(string) }
    set_handler(:enter, block)
  end

  def prompt(string=nil,&block)
    block ||= proc { send_data(string) }
    set_handler(:prompt, block)
  end

  def input(string=nil,&block)
    block ||= proc { send_line(string) }
    set_handler(:input, block)
  end

  def selection(p={},&block)
    raise ArgumentError, 'no choices' unless p[:choices]

    prompt((p[:prompt] || 'Choose') + ": ")

    p[:display] ||= proc { |c| c.inspect }
    enter do
      @choices = instance_eval(&p[:choices])
      buf = @choices.each_with_index.inject("\n") do |o,(c,i)|
        o << "% 3d) %s\n" % [i + 1, instance_exec(c, &p[:display])]
      end
      send_line(buf)
    end

    input do |line|
      index = line.to_i - 1
      if index >= 0 && choice = @choices[index]
        instance_exec(choice, &block)
        @choices = nil
      else
        send_line("Invalid option")
      end
    end
  end
end
