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
  class NoField < RuntimeError; end

  REFERENCE_PATTERN = %r{
    \A
    (?<area>[^:.]+):
    (?<virtual>[^:.]+)
    (?:\.
      (?<component>[^\.]+)
      \.
      (?<field>.*?)
    )?
    \Z
  }x

  # Reference.new("area:type/name")
  # Reference.new("type/name", source: path)
  # Reference.new(Entity)
  def initialize(arg)
    if arg.is_a?(Entity)
      @entity_id = arg.id
    else
      raise ArgumentError, "unsupported argument, #{arg.inspect}" unless
          @match = arg.match(REFERENCE_PATTERN)
    end
  end
  attr_reader :match, :entity_id

  # entity
  #
  # Return the Entity instance in World that this Reference refers to.  If no
  # such Entity exists, a EntityManager::UnknownVirtual exception will be
  # raised.
  def entity
    return World.by_id(@entity_id) if @entity_id

    entity = World.by_virtual("#{@match[:area]}:#{@match[:virtual]}")
    @entity_id = entity.id
    entity
  end

  # has_field?
  #
  # Returns true if the Reference is a Component field Reference
  def has_field?
    !!@match[:field]
  end

  # value
  #
  # For Component Field References, return the value of the Component Field.
  # If this Reference is not for a Component Field, raise an error
  def value
    raise NoField, "no component field found in #{@match[0].inspect}" unless
        has_field?

    entity.get(@match[:component], @match[:field])
  end

  # value=
  #
  # For Component Field References, set the value to the value provided.  If
  # this Reference is not for a Component Field, it will raise an error.
  def value=(val)
    raise NoField, "no component field found in #{@match[0].inspect}" unless
        has_field?
    entity.set(@match[:component], @match[:field] => val)
  end

  # absolute?
  #
  # Returns true if this is an absolute Reference to a specific Entity ID, not
  # a relative one from a reference string.
  def absolute?
    @match.nil?
  end

  # to_s
  #
  # Return a String representation for this Reference
  def to_s
    @match[0]
  end

  # YAML-base initialization
  YAML.add_tag '!ref', self
  def init_with(coder)
    raise RuntimeError, "invalid reference: %s " %
        [ coder.send(coder.type).inspect ] unless coder.type == :scalar
    buf = coder.scalar.to_s
    unless buf.include?(':')
      area = World.area_from_filename(YAML.current_filename)
      buf = "#{area}:#{buf}"
    end
    @match = buf.match(REFERENCE_PATTERN) or
        raise ArgumentError, "invalid reference, #{buf.inspect}"
  end

  def encode_with_old(coder)
    coder.scalar = full
  end
end
