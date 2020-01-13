<template>
  <v-card min-width="500px">
    <v-card-title>{{ id }}</v-card-title>
    <v-divider />
    <v-card-text>
      <v-row wrap>
        <v-col cols="12" sm="3" md="2" xl="1">base entities</v-col>
        <v-col v-if="base.length > 0">
          <v-chip small v-for="b in base" :key="b" class="mx-1">
            <!-- XXX fix this, tooltip should be on chip -->
            <v-tooltip bottom fluid>
              <template v-slot:activator="{ on }">
                <div v-on="on">{{ b }}</div>
              </template>
              <entity-card :id="b" />
            </v-tooltip>
          </v-chip>
        </v-col>
        <v-col v-else>none</v-col>
      </v-row>
      <v-divider />
      <div
        class="component"
        v-for="component in components"
        :key="component.id"
      >
        <v-row wrap no-gutters class="mb-2">
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
              <v-col class="ml-2" cols="2">{{ name }}</v-col>
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
      </div>
    </v-card-text>
  </v-card>
</template>

<script>
export default {
  name: "entity-card",
  props: {
    id: {
      type: String,
      required: true
    }
  },
  data: () => ({
    components: []
  }),
  computed: {
    base: function() {
      var metadata = this.get_component("metadata");
      return metadata ? metadata.fields.base.value : [];
    }
  },
  mounted: function() {
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

<style>
.component {
  border-top: 2px solid gray;
}
.row.field {
  border-left: 2px solid gray;
}
</style>
