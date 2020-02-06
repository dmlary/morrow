<template>
  <v-autocomplete
    :value="value"
    :dense="dense"
    :items="entities"
    :loading="loading"
    :error-messages="error_msg"
    :hint="hint"
    :label="label"
    :placeholder="placeholder"
    :append-outer-icon="appendOuterIcon"
    @input="$emit('input', $event)"
    @click:append-outer="$emit('click:append-outer', $event)"
    @update:search-input="do_search"
    clearable
    hide-no-data
  >
    <template #item="data">
      <slot v-bind:item="data.item">
        <entity-with-tooltip :id="data.item" />
      </slot>
    </template>
  </v-autocomplete>
</template>

<script>
export default {
  name: "entity-autocomplete",
  props: {
    value: String,
    label: String,
    placeholder: String,
    dense: Boolean,
    appendOuterIcon: String
  },
  data: () => ({
    entities: [],
    loading: false,
    error_msg: null,
    hint: null
  }),
  created: function() {
    this.debounced_fetch_entities = this._.debounce(this.fetch_entities, 450);
    if (this.value) {
      this.entities.push(this.value);
    }
  },
  watch: {
    value(v) {
      if (!this.entities.includes(v)) {
        this.entities = [v];
      }
    }
  },
  methods: {
    do_search(v) {
      /* with issue https://github.com/vuetifyjs/vuetify/issues/9489
       * we need to jump through a lot of hoops to prevent an infinite loop.
       * Basically whenever we update the items, the v-autocomplete is going to
       * fire a @update:search-input, which is going to cause us to update the
       * items again starting the whole cycle over again.
       *
       * The only way I've seen to avoid this is to not do anything if the
       * search term matches the value.  There's something more going on here,
       * but it works for now. */
      if (this.value == v) {
        this.loading = false;
        this.error_msg = null;
        return;
      }
      if (v == null || v.length < 3) {
        this.loading = false;
        this.error_msg = null;
        this.hint = "Minimum of 3 characters";
        return;
      }

      this.loading = true;
      this.error_msg = null;
      this.debounced_fetch_entities(v);
    },
    async fetch_entities(val) {
      this.hint = null;

      this.entities = await this.$morrow.get_entities(val);
      if (this.entities.length == 0) {
        this.error_msg = "No matches found";
      }
      this.loading = false;
    }
  }
};
</script>
