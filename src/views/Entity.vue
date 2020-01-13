<template>
  <div class="mx-5">
    <entity-card :id="this.$route.params.id" />
  </div>
</template>

<script>
export default {
  data: () => ({
    id: null,
    components: []
  }),
  computed: {
    base: function() {
      var metadata = this.get_component("metadata");
      return metadata ? metadata.fields.base.value : [];
    }
  },
  mounted: function() {
    this.id = this.$route.params.id;
    var url = process.env.VUE_APP_BACKEND_URL + "/entity/" + this.id;
    this.axios.get(url).then(response => {
      this.components = response.data.components.sort((a, b) =>
        a.name > b.name ? 1 : -1
      );
    });
  },
  methods: {
    get_component(name) {
      return this._.find(this.components, function(comp) {
        return comp.name == name;
      });
    }
  }
};
</script>
