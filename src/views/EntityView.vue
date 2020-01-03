<template>
  <div class="entity_view">
    <v-autocomplete
        v-model="model"
        :items="items"
      label="Entity" :loading="loading"
    <v-text-field />
  </div>
</template>

<script>
export default {
  data: () => ({
    model: null
    entities: [],

    entity: {}
  }),

  computed: {
    items() {},
  }
  mounted() {}
};
</script>
