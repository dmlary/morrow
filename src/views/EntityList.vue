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
    entities: ['wolf', 'bear']
  }),
  mounted() {
    var self = this;
    $.getJSON("/entities", function(data) {
      self.entities = data;
    });
  }
};
</script>
