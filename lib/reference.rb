require 'yaml'
require_relative 'helpers/psych'

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
      (?<area>[^/]+):
    )?
    (?<virtual>[^\.]+)
    (?:\.
      (?<component>[^\.]+)
      (?:\.
        (?<field>.*?)
      )?
    )?
    \Z
  }x

  # Reference.new("area:type/name")
  # Reference.new("type/name", source: path)
  # Reference.new(Entity)
  def initialize(arg, p={})
    case arg
    when String
      parse_ref(arg)
    when Entity
      @entity_id = arg.id
      virtual = arg.get(:ident, :virtual) and parse_ref(virtual)
    else
      raise ArgumentError, "unsupported argument type: #{arg}"
    end
  end
  attr_accessor :area, :virtual, :component, :field

  # YAML-base initialization
  YAML.add_tag '!ref', self
  def init_with(coder)
    raise RuntimeError, "invalid reference: %s " %
        [ coder.send(coder.type).inspect ] unless coder.type == :scalar
    parse_ref(coder.scalar.to_s, path: YAML.current_filename)
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
    entity = World.by_virtual("#{area}:#{@virtual}")
    @entity_id = entity.id
    entity
  end
  alias entity resolve

  def full
    return nil unless @virtual
    out = ''
    out << "#{@area}:" if @area
    out << "#{@virtual}"
    out << ".#{@component}" if @component
    out << ".#{@field}" if @field
    out
  end
  alias to_s full

  def component_field
    [ @component, @field ].compact if @component
  end

  def inspect
    "#<Reference:#{to_s || 'absolute'} id=#{@entity_id || :unresolved}>"
  end

  private
  def parse_ref(buf, path: nil)
    match = buf.match(Pattern) or raise InvalidReference, buf, path
    @virtual = match['virtual']
    @component = match['component']
    @field = match['field']
    unless @area = match['area']
      # determine area from the path; going to just use the first word after
      # world/ for right now
      raise "ref '#{buf}', couldn't determine area from path, '#{path}'" unless
          path =~ %r{world/([^/.]+)}
      @area = $1
    end
  end
end
