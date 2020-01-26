<template>
  <div class="mx-5">
    <entity-card :id="this.$route.params.id" />
  </div>
</template>

<script>
export default {
  data: () => ({
    id: null,
  }),
};
</script>
