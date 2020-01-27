<template>
  <div class="component-field-input">
    <entity-autocomplete
      v-if="type === 'entity'"
      v-model="local_value"
      v-on="on"
      :append-outer-icon="appendOuterIcon"
    />
    <v-text-field
      v-else-if="type === 'Integer'"
      :value="local_value"
      type="number"
      v-on="on"
      :append-outer-icon="appendOuterIcon"
    />
    <v-textarea
      v-else-if="typeof(local_value) === 'string'
          && local_value.indexOf('\n') != -1"
      :value="local_value"
      v-on="on"
      auto-grow
      autofocus
      filled
      counter
    />
    <template v-else-if="type instanceof Array">
      <component-field-input
        v-for="(v, index) in local_value"
        :key="index"
        :value="v"
        :type="type[0]"
        @input="local_value[index] = $event; $emit('input', local_value)"
        append-outer-icon="mdi-delete-outline"
        @click:append-outer="local_value.splice(index, 1); $emit('input', local_value)"
      />
      <component-field-input
        label="Add new value"
        v-model="new_value"
        :type="type[0]"
        append-outer-icon="mdi-plus-box-outline"
        @click:append-outer="add_array_value()"
        @keyup.enter="add_array_value()"
      />
    </template>

    <v-text-field
      v-else
      :value="value"
      :append-outer-icon="appendOuterIcon"
      v-on="on"
    />
  </div>
</template>

<script>
export default {
  name: "component-field-input",
  props: {
    value: { required: true },
    type: { required: true },
    appendOuterIcon: String
  },
  data: function() {
    return {
      local_value: this._.cloneDeep(this.value),
      new_value: null,
      on: {
        input: (ev) => { this.$emit('input', ev) },
        change: (ev) => { this.$emit('change', ev) },
        keyup: (ev) => { this.$emit('keyup', ev) },
        "click:append-outer": (ev) => { this.$emit("click:append-outer", ev) }
      }
    };
  },
  watch: {
    value: function(v) {
      return this.local_value = this._.cloneDeep(v);
    }
  },
  methods: {
    add_array_value: function() {
      this.local_value.push(this.new_value);
      this.new_value = null;
      this.$emit('input', this.local_value);
    }
  }
};
</script>
