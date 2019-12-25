require_relative '../helpers'

module System::Base
  include ::Helpers::Logging
  extend ::World::Helpers

  def send_data(buf, p={})
    entity = p[:entity] || @entity
    conn = get_component(entity, ConnectionComponent) or
        fault("Entity #{entity} has no connection", entity)
    conn.conn.send_data(buf)
  end
end
