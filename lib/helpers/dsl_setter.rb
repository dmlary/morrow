class Helpers::DslSetter
  class << self
    def set_instance(instance, &block)
      new(instance).instance_eval(&block)
      instance
    end
  end

  def initialize(instance)
    @instance = instance
  end

  def method_missing(name, *args, &block)
    return super unless @instance

    setter = "#{name}="
    @instance.respond_to?(setter) ?
        @instance.send(setter, *args, &block) :
        super
  end
end
