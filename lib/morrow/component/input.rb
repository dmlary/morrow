# Command queue for characters
class Morrow::Component::Input < Morrow::Component

  no_save

  # queue of commands to be processed
  field :queue, clone: false, type: Thread::Queue

  # time at which the next command in the queue can be processed
  field :blocked_until, type: Time
end

