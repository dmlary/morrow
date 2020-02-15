require 'facets/hash/rekey'

class Morrow::Loader
  include Morrow::Helpers

  SUPPORTED_KEYS = %w{ id base components update remove }

  def initialize
    @tasks = []   # Array of tasks to be performed at #finish
  end

  # Load entities from the YAML file provided.
  def load_file(file)
    buf = File.read(file)

    # parse the document into a Psych tree; we don't load here because we want
    # the file/line info while creating our entities.
    doc = YAML.parse(buf)

    # Document should be an Array of Hashes
    seq = doc.children.first or return    # ignore empty documents
    load_error!('not a yaml sequence (Array)', file, seq) unless seq.sequence?

    # Loop through each Hash
    seq.children.each do |map|

      # Make sure it's a mapping before we convert it to a ruby Hash
      load_error!('not a yaml mapping (Hash)', file, map) unless map.mapping?
      entity = map.to_ruby

      # Ensure they're not using some unknown keys
      unknown_keys = entity.keys - SUPPORTED_KEYS
      load_error!("unknown keys: #{unknown_keys}", file, map) unless
          unknown_keys.empty?

      load_error!("id and update are mutually exclusive", file, map) if
          entity['id'] and entity['update']

      source = "#{file}:#{map.start_line + 1}"

      create = {}
      create[:id] = entity['id'] if entity.has_key?('id')
      create[:update] = entity['update'] if entity.has_key?('update')

      # Create an Array of the various base Entities that will be layered into
      # this Entity
      create[:base] = [entity['base']].flatten.compact

      # Construct an Array of component arguments that will be sent to
      # Morrow::EntityManager#create_entity
      entity['components'] ||= []
      loader_error!('The `components` field must be an Array; %s' %
          [ entity['components'].inspect ], file, map) unless
              entity['components'].is_a?(Array)

      create[:components] = entity['components'].map do |conf|
        case conf
        when Symbol
          conf
        when String
          conf.to_sym
        when Hash
          loader_error!(<<~ERROR, file, map) unless conf.size == 1
            Multiple keys found in single component configuration.  Note that
            the `components` field is an Array.  Perhaps you missed a '-'
            before the next component after this one.
          ERROR

          # A Hash is a component with non-default values.  The values may be
          # provided as a Hash, an Array (must have all elements), or a scalar
          # (for single field Components)
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
          { comp.to_sym => config }
        else
          load_error!('Unsupported component configuration type: %s' %
              [ conf.inspect ], file, map)
        end
      end

      create[:remove] = entity['remove'] || []

      # defer the action if we're not able to do it at the moment
      begin
        create_or_update(**create)
      rescue Morrow::EntityManager::UnknownId
        defer(source: source, entity: create)
      rescue Exception => ex
        raise Morrow::Error, <<~ERROR.chomp
          error in entity file: #{source}: #{entity.pretty_inspect
                                .chomp.gsub(/\n/, "\n" + ' ' * 16)}
        ERROR
      end
    end

    # Attempt to flush any deferred actions now that we've loaded everything in
    # the file.
    flush
  end

  # Called once all calls to #load have been made
  def finalize

    # everything has been loaded, let's try to apply all the deferred things.
    flush

    # If flush wasn't able to do everything, print a very clear error why.
    unless @tasks.empty?
      @tasks.each do |task|
        error <<~ERROR.chomp
          unable to create entity
                  source: #{task[:source]}
                  error:  #{task[:last_error].inspect}
                  entity: #{task[:entity].pretty_inspect
                                .chomp.gsub(/\n/, "\n" + ' ' * 16)}
        ERROR
      end

      raise RuntimeError, 'unable to create deferred entities'
    end

    Morrow.em.flush_updates
  end

  private

  # load_error!
  #
  # Raise a clang-style loader error
  def load_error!(msg, path, node)
    line = node.start_line + 1
    column = node.start_column
    raise "#{path}:#{line}:#{column}: error: #{msg}"
  end

  # defer the creation of this entity until after more entities have been
  # created.  This is called due to a missing dependency.
  def defer(source:, entity:)
    @tasks << { source: source, entity: entity, last_error: nil }
  end

  # create or update an entity.  This is an awful interface that grew out of
  # multiple changes; it needs to be cleaned up.
  def create_or_update(id: nil, update: nil, base: [], components: [],
      remove: [])
    if update
      entity_exists!(update)
      tmp = Morrow.em.create_entity(base: base, components: components)
      Morrow.em.merge_entity(update, tmp)
      Morrow.em.destroy_entity(tmp)

      remove.each { |c| remove_component(update, c.to_sym) }

      # patch up the metadata
      metadata = get_component!(update, :metadata)
      metadata.base ||= []
      metadata.base += base

      debug "updated entity #{update}"
    else
      entity = create_entity(id: id, base: base, components: components)
      remove.each { |c| remove_component(entity, c.to_sym) }
      debug "created entity #{entity}"
      entity
    end
  end

  # attempt to perform any deferred entity creation
  def flush
    loop do
      before = @tasks.size

      @tasks.delete_if do |task|
        create_or_update(**task[:entity])
      rescue Morrow::EntityManager::UnknownId => ex
        task[:last_error] = ex
        false
      end

      break if @tasks.empty? or @tasks.size == before
    end
  end
end
