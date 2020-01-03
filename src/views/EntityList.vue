<template>
  <div class="entity_list">
    <ul>
      <li v-for="entity in entities" :key="entity">
        {{ entity }}
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  data: () => ({
    entities: ["wolf", "bear"]
  }),
  mounted() {
    this.axios
      .get("entities")
      .then(response => (this.entities = response.data));
  }
};
</script>
