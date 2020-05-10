# Denotes the visibility of the component in the world, and which of it's
# peer Components are visible to 'look'.
#
# | type | short | long | desc | contents | exits | keywords |
# | ---- | ----- | ---- | ---- | -------- | ----- | -------- |
# | room | yes   | nil  | yes  | :long    | true  | false    |
# | char | yes   | yes  | yes  | nil      | false | true     |
# | obj  | yes   | yes  | yes  | :short   | false | true     |
# | extra| nil   | nil  | yes  | nil      | false | false    |
# | exit | yes   | nil  | yes  | nil      | false | false    |
#
class Morrow::Component::Viewable < Morrow::Component

  # char name, object name, room title
  field :short, freeze: true, type: String

  # object resting on the ground; npc standing
  field :long, freeze: true, type: String

  # character, item, or room desc
  field :desc, freeze: true, type: String

  # Formatter to use when looked at.
  field :formatter, type: String, valid: %s{ room obj char exit desc_only }

  # Container contents are viewable
  field :contents, type: :boolean, default: false
end

