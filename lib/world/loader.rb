require_relative '../world'

class World::Loader
  include Helpers::Logging

  # World::Loader::Base
  #
  # superclass of all loaders
  class Base
    extend Helpers::Logging
    include Helpers::Logging

    class << self

      # inherited
      #
      # Auto-register any sub-classes
      def inherited(other)
        World::Loader.register_loader(other)
      end

      # load
      #
      # initialize a new loader instance, and call load(path)
      #
      # Arguments:
      #   scheduler: World::Loader instance
      #   path: filename to load
      #   area: area this file belongs to
      def load(loader: nil, path: nil, area: nil)
        new(loader).load(path: path, area: area)
      end

      # can_load?
      #
      # Checks to see if the loader can support a given file
      def can_load?(path)
        raise RuntimeError, "define this method in #{self}"
      end
    end

    # initialize
    #
    # Arguments:
    #   loader: World::Loader instance used to schedule entity creation
    def initialize(loader)
      @loader = loader
    end

    # load
    #
    # Arguments:
    #   path: file to load
    #   area: area the file belongs to
    def load(path: nil, area: 'unknown')
      raise RuntimeError, "define this method in #{self.class}"
    end
  end

  # All registered loaders
  @registered_loaders = []

  # Class methods
  class << self

    # register_loader
    #
    # Register a loader for use
    def register_loader(klass)
      @registered_loaders << klass unless @registered_loaders.include?(klass)
    end

    # get_loader
    #
    # Get the loader for the specified file
    def get_loader(path)
      @registered_loaders.find { |l| l.can_load?(path) }
    end
  end

  def initialize(em)
    @em = em      # EntityManager
    @tasks = []   # Array of tasks to be performed at #finish
  end

  # load
  #
  # Load a specific file.
  def load(path: nil, area: 'unknown')
    unless loader = self.class.get_loader(path)
      warn "no loader found for #{path}; skipping"
      return
    end
    loader.load(loader: self, path: path, area: area)
  end

  # finish
  #
  # Called once all calls to #load have been made
  def finish
    loop do
      before = @tasks.size
      @tasks.delete_if do |task,arg|
        res = handle_task(task, arg)
        res
      end
      break if @tasks.empty? or @tasks.size == before
    end

    return if @tasks.empty?

    @tasks.each do |action, args|
      error "failed to resolve: #{action}, #{args.inspect}"
    end
    raise RuntimeError, 'failed to resolve all scheduled actions' unless
        @tasks.empty?
  end

  # schedule
  #
  # Schedule some action; used by per-file loaders
  #
  # Arguments:
  #   action: action to perform
  #   args: arguments
  def schedule(action, args)
    @tasks << [ action, args ]
  end

  private

  # handle_task
  #
  # Handle a given task that was scheduled via #schedule().  Called from
  # #finish().
  #
  # Returns:
  #   false if the task cannot be performed yet
  #   true if the task was completed
  def handle_task(task, arg)
    case task
    when :create_entity
      try_create_entity(arg)
    when :link
      try_link_entity(arg)
    else
      raise ArgumentError, "unknown task #{task}"
    end
  end

  # try_create_entity
  #
  # Try to create an entity; if it fails due to UnknownId, return false
  def try_create_entity(id: nil, base: [], components: [], link: [])
    begin
      id = @em.create_entity(id: id, base: base, components: components)
      link.each do |dest|
        schedule(:link, entity: id, dest: dest)
      end
      debug "created entity #{id}"
      true
    rescue EntityManager::UnknownId
      false
    end
  end

  LINK_PATTERN = %r{
    \A
    (?<id>[^.]+)\.
    (?<component>[^\.]+)\.
    (?<field>.*?)
    \Z
  }x

  # try_link_entity
  #
  # Try to link an entity to some destination.  If it fails due to UnknownId,
  # this method will return false
  def try_link_entity(entity: nil, dest: nil)
    link = dest.match(LINK_PATTERN) or
        raise ArgumentError, "Invalid link format: #{dest}"
    _, id, component, field = link.to_a
    component = component.to_sym

    begin
      comp = @em.get_component(id, component)
      comp ||= @em.add_component(id, component)

      binding.pry if comp != @em.get_component(id, component)

      value = comp.send(field)

      if value.is_a?(Array)
        value << entity
      else
        comp.send("%s=" % field, entity)
      end
      debug "linked #{entity} to #{dest}"
      true
    rescue EntityManager::UnknownId
      false
    end
  end
end

require_relative 'loader/yaml'
