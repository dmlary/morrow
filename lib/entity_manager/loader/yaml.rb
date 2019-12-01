class EntityManager::Loader::Yaml < EntityManager::Loader::Base
  class << self
    def support?(path)
      !!(path =~ /\.ya?ml$/i)
    end
  end

  SUPPORTED_KEYS = %w{ template components link }

  def load(path)
    raw = YAML.load_file(path)

    raw.each do |definition|
      unknown_keys = definition.keys - SUPPORTED_KEYS
      unless unknown_keys.empty?
        raise "unknown keys #{unknown_keys.join(',')} in #{definition.inspect}"
      end

      templates = [definition["template"]].flatten.compact
      components = definition["components"].map do |conf|
        case conf
        when String, Symbol
          [ conf ]
        when Hash
          conf.first
        else
          raise RuntimeError, "Unsupported component config #{conf.inspect}"
        end
      end
      components << [ :loaded, path ]
      links = [definition["link"]].flatten.compact

      area = path =~ %r{/world/([^/.]+)} ? $1 : nil

      @manager.create(template: templates, components: components,
          area: area, links: links)
    end
  end
end
