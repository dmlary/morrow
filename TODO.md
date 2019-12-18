* [X] color
* [ ] real systems implementation
* [X] removal of entities from World
* [X] World tests, including stress test with 10000's of entities
* [X] command expansion
    * register commands with priorities; exact match wins; highest priority
      partial match after
* [ ] command wait-state/wait-state mechanism from command
* [X] generic error method
    * [X] save error to system-wide error log w/ binding
    * [X] write error message to error log
    * [ ] send error to user
* [ ] not_implemented method; output message to entity
* [X] Entity composition
    * [X] implementation
    * [X] tests
* [ ] WBR area file loader
* [ ] Entity save method
* [ ] Unload Entities from a given source filename
    * [ ] reload a specific source filename
* [ ] Implement entity tags
    * ~~Alternate: regex support for `entity_by_virtual`~~ not everything will
      have a virtual

* [ ] Entity.to_s helper; sometimes I need to log an entity without all the
  spam
* [ ] Move EntityView into EntityManager
    * makes sense because add actually happens in there
    * [ ] Add a Component to exclude an Entity from EntityView by default
        * The template for limbo-chest is spawning balls inside it
        * Need to flag mob/item templates from being included in systems
        * Need to auto-remove that Component when cloning
            * Is this a Component that is cloned, but spawn explicitly removes
              it?
        * By default, EntityView should add ExcludeSystemsComponent to the
          exclude list unless it's in one of the other lists
* [ ] Combat system
* [ ] import socials
    * [ ] Implement `act()` and `send_to_room()`
    * [ ] Queue output on the ConnectionComponent
* [ ] match_keywords() updates to support prefix (config-able?)
* [ ] Make open/close affect the other side of a passage
