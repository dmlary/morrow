require 'yaml'

class Reference
  YAML.add_tag '!ref', self

  attr_accessor :value
  def init_with(coder)
    @value = coder.send(coder.type)
  end
end
