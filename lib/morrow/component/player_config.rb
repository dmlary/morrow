# Player configuration data
class Morrow::Component::PlayerConfig < Morrow::Component

  # enable color output
  field :color, type: :boolean, default: false, valid: [ true, false ]

  # enable coder output
  field :coder, type: :boolean, default: false, valid: [ true, false ]

  # enable compact output
  field :compact, type: :boolean, default: false, valid: [ true, false ]

  # send telnet go-ahead codes
  field :send_go_ahead, type: :boolean, default: false, valid: [ true, false ]
end
