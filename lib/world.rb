module World
  @entities = []
  @entities_by_tag = Hash.new { |h,k| h[k] = [] }
  class << self
    def new_entity(tag)
      entity = Entity.new(tag)
      @entities << entity
      @entities_by_tag[tag] << entity if tag
      entity
    end
  end
end
