require_relative '../helpers'

module System::Base
  include ::Helpers::Logging
  extend ::World::Helpers

  def send_data(buf, p={})
    entity = p[:entity] || @entity
    conn = entity.get(ConnectionComponent, :conn) or
        fault("Entity #{entity} has no connection", entity)
    conn.send_data(buf)
    entity
  end
end
