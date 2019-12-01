require 'set'
require_relative 'entity'
require_relative 'helpers'

class EntityManager
  include Helpers::Logging

  class UnsupportedFileType < ArgumentError; end
  class UnknownVirtual < ArgumentError; end

  @loaders = Set.new
  class << self
    def register_loader(other)
      @loaders << other
    end

    def get_loader(path)
      @loaders.find { |l| l.support?(path) }
    end
  end

  def initialize()
    @entities = []
    @deferred = []
  end
  attr_reader :entities, :pending

  # Load entities from the file at +path+
  def load(path)
    loader = EntityManager.get_loader(path) or
        raise UnsupportedFileType, path
    info "loading entities from #{path}"
    loader.load(self, path)
  end

  # clear all entities from the system
  def clear
    @entities.clear
    @deferred.clear
  end

  # lookup an entity by a virtual id
  def entity_by_virtual(virtual)
    @entities.find { |e| e.get(:virtual) == virtual } or
        raise UnknownVirtual, virtual
  end

  # lookup an entity by an entity id
  def entity_by_id(id)
    ObjectSpace._id2ref(id)
  end

  def entity_from_template(*templates)
    base = Entity.new
    templates.flatten.compact.each do |virtual|
      apply_template(base, entity_by_virtual(virtual))
    end
    base
  end

  def create(components: [], template: [], area: nil, links: [], defer: true)
    # create our template entity
    base = Entity.new

    # Apply any templates we can find; if we fail to find one, throw the entity
    # definition in the incomplete list for later resolution
    base = begin
      entity_from_template(template)
    rescue UnknownVirtual => ex
      if defer
        # Patch up the template virtuals for the area name if it's absent
        template.map! { |t| t =~ %r{^[^\/]+:} ? t : ("#{area}:" << t) }
        deferred_entity_create(template: template, components: components,
            area: area, links: links)
      end
      return nil
    end

    # This entity will be the modifications we'll make to the template
    modifications = Entity.new

    # Now throw on all the other components
    components.each do |type, config|
      component = Component.new(type, config)
      if area and component.type == :virtual and virtual = component.get
        component.set(virtual.gsub(/^([^:]+:)?/, '%s:' % area))
      end
      modifications.add(component)
    end

    # apply our modifications to the base
    apply_template(base, modifications)
 
    add(base)
    links.each { |ref| deferred_link(ref, base) }
    base
  end

  def add(entity)
    @entities << entity
    entity
  end

  def resolve_deferred!
    info "resolving deferred entity creation & linking"
    loop do
      before = @deferred.size 

      @deferred.delete_if do |type, arg|
        case type
        when :create
          create(arg.merge(defer: false))
        when :link
          begin
            ref = arg[:ref]
            ref.resolve.set(*ref.component_field, arg[:entity])
            true
          rescue UnknownVirtual
            false
          end
        end
      end

      break if @deferred.empty? or @deferred.size == before
    end

    raise 'Failed to resolve all deferred items' unless @deferred.empty?
    info "all entities created & linked"
  end

  private

  def deferred_entity_create(cfg)
    @deferred << [ :create, cfg ]
  end

  def deferred_link(ref, entity)
    raise ArgumentError, "not a Reference: #{ref}" unless ref.is_a?(Reference)
    @deferred << [ :link, { ref: ref, entity: entity } ]
  end

  def apply_template(out, template)
    # out union template effectively, but a little nicer about defaults
    template.components.each do |component|

      if component.unique? && out.has_component?(component.type)
        # This component is limited to 1 per-Entity, and the component already
        # exists on the entity, so we'll take all the changes that have been
        # made to the component on the template, and apply them to the output
        # entity.
        component.changed_fields.each do |field, value|

          # XXX temporary special handing for arrays; we merge fields that are
          # arrays, but this may go away when we encounter more Array fields in
          # entities
          if value.is_a?(Array)
            out.get(component.type, field).push(*value).uniq!
          else
            out.set(component.type, field, value)
          end
        end
      else
        out.add(component.clone)
      end
    end
  end

  def virtual_in_area(virtual, area)
    area ? virtual.gsub(/^([^:]+:)?/, '%s:' % area) : virtual
  end
end

require_relative 'entity_manager/loader'
