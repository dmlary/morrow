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

    raw.each do |definition|
      unknown_keys = definition.keys - SUPPORTED_KEYS
      unless unknown_keys.empty?
        raise "unknown keys #{unknown_keys.join(',')} in #{definition.inspect}"
      end

      base = [definition["base"]].flatten.compact
      components = (definition["components"] || {}).map do |conf|
        case conf
        when String, Symbol
          [ Component.find(conf) ]
        when Hash
          comp, config = conf.first
          case config
          when Hash
            config.rekey! { |k| k.to_sym }
          when Array
          else
            config = [ config]
          end
          [ Component.find(comp), config ]
        else
          raise RuntimeError, "Unsupported component config #{conf.inspect}"
        end
      end
      links = [definition["link"]].flatten.compact

      area = path =~ %r{/world/([^/.]+)} ? $1 : nil

      components << [ LoadedComponent,
          area: area,
          save_hints: {path: path, base: base, link: links} ]

      @manager.define_entity(base: base, components: components,
          area: area, links: links)
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
