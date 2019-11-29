require 'yaml'

module PsychYamlPruner
  def emit_coder(c,o)
    # XXX not called because doesn't have encode_with
    #return if o.is_a?(::Component) and !o.savable?
    super
  end
end

class Psych::Visitors::YAMLTree
  #prepend PsychYamlPruner
end

class Reference
  def initialize(vid)
    @vid = vid.to_s
  end
  attr_reader :vid

  # YAML-base initialization
  YAML.add_tag '!ref', self
  def init_with(coder)
    raise RuntimeError, "invalid vid, #{coder.send(coder.type).inspect}" unless
        coder.type == :scalar
    @vid = coder.scalar.to_s
  end

  def encode_with(coder)
    coder.scalar = @vid
  end

  def resolve(component)
    @id ||= case @vid
      when Integer
        @vid
      else
        # XXX this may be slow, but not optimizing yet

        # expand the referenced vid if necessary
        vid, type, area = @vid.split('/', 3).reverse

        # XXX type should be enforced somehow

        unless area
          entity = World.entities.find { |e| e.components.include?(component) }
          if source = entity.get(:loaded, :source)
            area = File.dirname(source)
          else
            area = '<none>'
          end
        end

        World.by_vid("#{area}/#{type}/#{vid}").id
      end

    World.by_id(@id)
  end
end
