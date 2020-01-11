<template>
  <div class="mx-5">
    <v-card>
      <v-card-title>{{ id }}</v-card-title>
      <v-card-text>
        <v-row wrap>
          <v-col cols="12" sm="3" md="2" xl="1">Base Entities</v-col>
          <v-col v-if="base.length > 0">
            <v-chip small v-for="b in base" :key="b" class="mx-1">
              {{ b }}
            </v-chip>
          </v-col>
          <v-col v-else>none</v-col>
        </v-row>
        <v-divider />
        <div v-for="component in components" :key="component.id">
          <v-row wrap>
            <v-col cols="12" md="2" class="font-weight-bold">
              <v-tooltip top>
                <template v-slot:activator="{ on }">
                  <div v-on="on">{{ component.name }}</div>
                </template>
                <v-card>
                  <v-card-title>{{ component.name }}</v-card-title>
                  <v-card-text>
                    <pre>{{ component.desc }}</pre>
                  </v-card-text>
                </v-card>
              </v-tooltip>
            </v-col>

            <v-col cols="12" md="10">
              <v-row
                class="field"
                wrap
                no-gutters
                v-for="(data, name) in component.fields"
                :key="component.id + name"
              >
                <v-col cols="2">{{ name }}</v-col>
                <v-col
                  v-if="data.value != data.default"
                  class="primary--text text--lighten-1"
                >
                  {{ data.value ? data.value : "nil" }}
                </v-col>
                <v-col v-else class="grey--text">
                  {{ data.value ? data.value : "nil" }}
                </v-col>
              </v-row>
            </v-col>
          </v-row>
          <v-divider />
        </div>
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
