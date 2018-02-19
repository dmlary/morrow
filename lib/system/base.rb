require_relative '../helpers'

module System::Base
  include ::Helpers::Logging
  extend ::World::Helpers

  def send_data(buf, p={})
    entity = p[:entity] || @entity
    conn = entity.get(:connection) or raise RuntimeError,
            'send_line(%s) failed; entity has no connection' %
                entity.inspect
    conn.send_data(buf)
    entity
  end
end
