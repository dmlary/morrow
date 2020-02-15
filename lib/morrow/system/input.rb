# Input system is responsible for pulling commands off the CommandQueue
# components and processing them.
module Morrow::System::Input
  extend Morrow::System

  class << self
    def view
      { all: :input }
    end

    def update(actor, input)
      queue = input.queue or return
      return if queue.empty?

      cmd = queue.shift
      run_cmd(actor, cmd)
    rescue Exception => ex
      log_exception(ex)
      send_to_char(char: actor, buf: 'error in command; logged to admin')
    end
  end
end
