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
  class InvalidReference < ArgumentError; end

  Pattern = %r{
    \A
    (?:
      (?<area>[^/]+)/
    )?
    (?<type>[^/]+)/
    (?<virtual>[^\.]+)
    (?:\.
      (?<component>[^\.]+)
      (?:\.
        (?<field>.*?)
      )?
    )?
    \Z
  }x

  # Reference.new("area/type/name")
  # Reference.new(Entity)
  def initialize(arg)
    case arg
    when String
      parse_ref(buf)
    when Entity
      @entity_id = arg.id
      virtual = arg.get(:ident, :virtual) and parse_ref(virtual)
    else
      raise ArgumentError, "unsupported argument type: #{arg}"
    end
  end
  attr_accessor :area, :type, :virtual, :component, :field

  # YAML-base initialization
  YAML.add_tag '!ref', self
  def init_with(coder)
    raise RuntimeError, "invalid reference: %s " %
        [ coder.send(coder.type).inspect ] unless coder.type == :scalar
    parse_ref(coder.scalar.to_s)
  end

  def encode_with(coder)
    coder.scalar = full
  end

  def resolve(source=nil)
    return World.by_id(@entity_id) if @entity_id

    raise RuntimeError,
        "cannot resolve relative reference, #{full}, without source" \
        unless @area || source

    area = @area || source.get(:loaded, :path).split('/').first
    entity = World.by_virtual("#{area}/#{@type}/#{@virtual}")
    @entity_id = entity.id
    entity
  end

  def full
    return nil unless @virtual
    out = ''
    out << "#{@area}/" if @area
    out << "#{@type}/#{@virtual}"
    out << ".#{@component}" if @component
    out << ".#{@field}" if @field
    out
  end
  alias to_s full

  def component_field
    [ @component, @field || :value ] if @component
  end

  def inspect
    "#<Reference:#{to_s || 'absolute'} id=#{@entity_id || :unresolved}>"
  end

  private
  def parse_ref(buf)
    match = buf.match(Pattern) or raise InvalidReference, buf
    @area = match['area']
    @type = match['type']
    @virtual = match['virtual']
    @component = match['component']
    @field = match['field']
  end
end
