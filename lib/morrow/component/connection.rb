# Player connection
class Morrow::Component::Connection < Morrow::Component
  no_save

  # TelnetServer::Connection instance
  field :conn

  # pending output buffer; will be sent by Morrow::System::Connection
  field :buf, default: '', type: String

  # Last time any input was received on this connection; updated by whichever
  # server is handling conn.
  field :last_recv, type: Time, default: proc { Time.now }

  # Last time this connection sent data to the client; updated by
  # Morrow::System::Connection.
  field :last_send, type: Time, default: proc { Time.now }
end
