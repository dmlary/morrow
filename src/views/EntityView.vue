<template>
  <div class="entity_view">
    <v-autocomplete
      v-model="model"
      :items="items"
      label="Entity"
      :loading="loading"
    />
  </div>
</template>

<script>
export default {
  data: () => ({
    model: null,
    entities: [],
    entity: {}
  }),

  computed: {},

  mounted() {}
};
</script>
