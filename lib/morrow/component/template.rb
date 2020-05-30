# This component is added to entities that should not be acted upon by most
# systems.  When Helpers#spawn is called on an entity with this component, any
# field that contains a Function will be evaluated.
class Morrow::Component::Template < Morrow::Component
  no_save
end
