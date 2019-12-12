require 'facets/hash/rekey'

class EntityManager::Loader::Yaml < EntityManager::Loader::Base
  class << self
    def support?(path)
      !!(path =~ /\.ya?ml$/i)
    end
  end

  SUPPORTED_KEYS = %w{ base components link }

  def load(path)
    raw = YAML.load_file(path)

    # Figure out the area name from the path
    area = World.area_from_filename(path)
    area_prefix = "#{area}:"

    raw.each do |definition|
      unknown_keys = definition.keys - SUPPORTED_KEYS
      unless unknown_keys.empty?
        raise "unknown keys #{unknown_keys.join(',')} in #{definition.inspect}"
      end

      # Create an Array of the various base Entities that will be layered into
      # this Entity
      base = [definition["base"]].flatten.compact

      # Links are an Array of References (!ref -> Reference done in yaml.load)
      links = [definition["link"]].flatten.compact

      # Construct an Array of Component instances
      components = (definition["components"] || {}).map do |conf|
        case conf

        # A bare String or Symbol means to include the Component with defaults
        when String, Symbol
          Component.find(conf).new

        # A Hash is a component with non-default values.  The values may be
        # provided as a Hash, an Array (must have all elements), or a bare
        # value (for single field Components.
        when Hash
          comp, config = conf.first
          case config
          when Hash
            config.rekey! { |k| k.to_sym }
          when Array
            # don't make any changes
          else
            # turn this non-array value into an array of a single element
            config = [ config ]
          end

          Component.find(comp).new(config)
        else
          raise RuntimeError, "Unsupported component config #{conf.inspect}"
        end
      end

      # Before we schedule anything, sweep through the components, and if
      # there's a VirtualComponent, update it to have the correct area name.
      if virtual = components.find { |c| c.is_a?(VirtualComponent) }
        virtual.id = virtual.id.sub(/^([^.:]+:)?/, area_prefix)
      end

      # Also add a LoadedComponent to say where the entity came from
      components << LoadedComponent.new(area: area,
          save_hints: { path: path, base: base, link: links})

      @manager.schedule(:new_entity,
          [ *base, components: components, links: links, add: true ])
    end
  end

  # Saving:
  #   * every entity as it is
  #     * simple
  #     * lose bases, defaults [THIS IS BAD]
  #     * if a default value changes after it's been saved, you have to go
  #       update all the old ones
  #   * entity - base, remaining components
  #     * simple-ish
  #     * retain bases
  #     * changes to component defaults not propigated
  #   * entity - base, per-component diff
  #     * complex
  #     * minimal output
  def save(path, *entities)
    entities.flatten.map do |entity|
      loaded = entity.get(:loaded)
      record = { base: loaded[:base] || [], links: loaded[:links] || [],
          components: [] }

      base = World.new_entity(loaded[:base])

      binding.pry
    end
  end
end
