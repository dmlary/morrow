<template>
  <div class="mx-5">
    <v-card>
      <v-card-title>{{ id }}</v-card-title>
      <v-card-text>
        <v-row wrap v-for="(component,index) in components" :key="index">
          <v-col sm=12 md=2>{{ component.name }}</v-col>
          <v-col sm=12 md=10>{{ component.fields }}</v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </div>
</template>

<script>
export default {
  data: () => ({
    id: null,
    components: []
  }),
  mounted: function() {
    this.id = this.$route.params.id;
    var url = process.env.VUE_APP_BACKEND_URL + "/entity/" + this.id
    this.axios
      .get(url)
      .then(response => {
        this.components = response.data.components;
      })
  }
};
</script>
