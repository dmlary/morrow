module Helpers::Loadable
  class << self
    def included(base)
      base.include(Helpers::Attributes)
      base.extend(ClassMethods)
    end
  end

  module ClassMethods
    attr_reader :load_handler
    def on_load(&block)
      @load_handler = block
    end
  end

  def init_with(data)

    # support Helpers::Attributes here by calling the default attribute setter
    klass = self.class
    klass.set_default_values(self) if klass.respond_to?(:set_default_values)

    # load the actual data
    data.map.each { |k,v| send("#{k}=", v) }

    # if there was a load handler, call it
    handler = self.class.load_handler and self.instance_exec(&handler)
  end
end
