<template>
  <v-autocomplete
    :value="value"
    @input="$emit('input', $event)"
    :dense="dense"
    :items="entities"
    :search-input.sync="search"
    :loading="loading"
    :error-messages="error_msg"
    :hint="search && search.length < 3 ? 'Minimum of 3 characters' : ''"
    :label="label"
    :placeholder="placeholder"
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
    dense: Boolean
  },
  data: () => ({
    entities: [],
    search: null,
    loading: false,
    error_msg: null,
    hint: null
  }),
  created: function() {
    this.debounced_fetch_entities = this._.debounce(this.fetch_entities, 450);
    if (this.value) {
      this.entities = [this.value];
    }
  },
  watch: {
    search(val) {
      if (this.search == null) {
        this.entities = [];
      } else if (this.value != this.search) {
        this.loading = true;
        this.error_msg = null;
        this.debounced_fetch_entities(val);
      }
    }
  },
  methods: {
    async fetch_entities(val) {
      if (val == null || val.length < 3) {
        this.loading = false;
        this.hint = "Minimum of 3 characters";
        return;
      }

      if (val.length < 3) {
        return;
      }

      this.entities = await this.$morrow.get_entities(val);
      if (this.entities.length == 0) {
        this.error_msg = "No matches found";
      }

      this.loading = false;
    }
  }
};
</script>
