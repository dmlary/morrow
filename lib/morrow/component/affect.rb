# affects; not really in use yet
class Morrow::Component::Affect < Morrow::Component

  not_unique
  # Component to which this affect applies
  field :component

  # field in the component to which this affect applies
  field :field

  # Affect type; :set, :delta, :push
  field :type

  # value to use for affect
  field :value
end
